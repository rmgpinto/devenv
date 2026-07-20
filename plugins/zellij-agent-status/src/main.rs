use std::collections::{hash_map::DefaultHasher, BTreeMap, HashMap, HashSet};
use std::hash::{Hash, Hasher};

use zellij_tile::prelude::*;

const POLL_INTERVAL_SECONDS: f64 = 0.25;

struct PluginConfig {
    terminal_title: String,
    working: String,
    waiting: String,
    idle: String,
    unknown: String,
}

impl Default for PluginConfig {
    fn default() -> Self {
        Self {
            terminal_title: "{session} | 󰚩 {agent_status}".into(),
            working: "∙".into(),
            waiting: "◆".into(),
            idle: "∘".into(),
            unknown: "×".into(),
        }
    }
}

impl PluginConfig {
    fn from_map(configuration: &BTreeMap<String, String>) -> Self {
        let mut config = Self::default();
        for (key, value) in configuration {
            match key.as_str() {
                "terminal_title" => config.terminal_title.clone_from(value),
                "agent_status_working" => config.working.clone_from(value),
                "agent_status_waiting" => config.waiting.clone_from(value),
                "agent_status_idle" => config.idle.clone_from(value),
                "agent_status_unknown" => config.unknown.clone_from(value),
                _ => {}
            }
        }
        config
    }

    fn status(&self, status: Status) -> &str {
        match status {
            Status::Working => &self.working,
            Status::Waiting => &self.waiting,
            Status::Idle => &self.idle,
            Status::Unknown => &self.unknown,
        }
    }

    fn format_title(&self, session: &str, status: Status) -> String {
        self.terminal_title
            .replace("{session}", session)
            .replace("{agent_status}", self.status(status))
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Agent {
    Claude,
    Codex,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Status {
    Waiting,
    Working,
    Idle,
    Unknown,
}

#[derive(Clone, Copy)]
struct AgentState {
    agent: Agent,
    status: Status,
    signature: u64,
    activity: u64,
}

struct State {
    config: PluginConfig,
    permissions_requested: bool,
    permissions_granted: bool,
    session_name: String,
    terminal_panes: HashSet<PaneId>,
    pane_titles: HashMap<PaneId, String>,
    agents: HashMap<PaneId, AgentState>,
    activity: u64,
    last_terminal_title: Option<String>,
}

impl Default for State {
    fn default() -> Self {
        Self {
            config: PluginConfig::default(),
            permissions_requested: false,
            permissions_granted: false,
            session_name: String::new(),
            terminal_panes: HashSet::new(),
            pane_titles: HashMap::new(),
            agents: HashMap::new(),
            activity: 0,
            last_terminal_title: None,
        }
    }
}

register_plugin!(State);

impl ZellijPlugin for State {
    fn load(&mut self, configuration: BTreeMap<String, String>) {
        self.config = PluginConfig::from_map(&configuration);
        subscribe(&[
            EventType::PaneUpdate,
            EventType::SessionUpdate,
            EventType::PermissionRequestResult,
            EventType::Timer,
        ]);
        set_timeout(POLL_INTERVAL_SECONDS);
    }

    fn update(&mut self, event: Event) -> bool {
        match event {
            Event::PermissionRequestResult(PermissionStatus::Granted) => {
                self.permissions_granted = true;
                self.refresh_session_snapshot();
                subscribe(&[EventType::PaneUpdate, EventType::SessionUpdate]);
                self.poll_agents();
            }
            Event::PermissionRequestResult(PermissionStatus::Denied) => {
                self.permissions_granted = false;
            }
            Event::PaneUpdate(panes) if self.permissions_granted => {
                self.update_panes(&panes);
                self.poll_agents();
            }
            Event::SessionUpdate(sessions, _) if self.permissions_granted => {
                if let Some(session) = sessions.iter().find(|session| session.is_current_session) {
                    self.session_name.clone_from(&session.name);
                    self.update_panes(&session.panes);
                    self.update_terminal_title();
                }
            }
            Event::Timer(_) => {
                if !self.permissions_requested {
                    request_permission(&[
                        PermissionType::ReadApplicationState,
                        PermissionType::ReadPaneContents,
                        PermissionType::ChangeApplicationState,
                    ]);
                    self.permissions_requested = true;
                } else if self.permissions_granted {
                    self.poll_agents();
                }
                set_timeout(POLL_INTERVAL_SECONDS);
            }
            _ => {}
        }
        false
    }

    fn render(&mut self, _rows: usize, _cols: usize) {}
}

impl State {
    fn refresh_session_snapshot(&mut self) {
        let Ok(snapshot) = get_session_list() else {
            return;
        };
        if let Some(session) = snapshot
            .live_sessions
            .iter()
            .find(|session| session.is_current_session)
        {
            self.session_name.clone_from(&session.name);
            self.update_panes(&session.panes);
        }
    }

    fn update_panes(&mut self, manifest: &PaneManifest) {
        let mut terminal_panes = HashSet::new();
        let mut pane_titles = HashMap::new();
        for panes in manifest.panes.values() {
            for pane in panes {
                if !pane.is_plugin && !pane.exited && !pane.is_held {
                    let pane_id = PaneId::Terminal(pane.id);
                    terminal_panes.insert(pane_id);
                    pane_titles.insert(pane_id, pane.title.clone());
                }
            }
        }
        self.terminal_panes = terminal_panes;
        self.pane_titles = pane_titles;
        self.agents
            .retain(|pane_id, _| self.terminal_panes.contains(pane_id));
    }

    fn poll_agents(&mut self) {
        let panes = self.terminal_panes.iter().copied().collect::<Vec<_>>();
        let mut detected = HashSet::new();

        for pane_id in panes {
            let Ok(command) = get_pane_running_command(pane_id) else {
                continue;
            };
            let Some(agent) = agent_from_command(&command) else {
                continue;
            };
            detected.insert(pane_id);

            let Ok(contents) = get_pane_scrollback(pane_id, true) else {
                continue;
            };
            let screen = pane_contents_to_string(contents);
            let title = self
                .pane_titles
                .get(&pane_id)
                .map(String::as_str)
                .unwrap_or_default();
            let status = parse_agent_screen_status(agent, title, &screen);
            let signature = screen_signature(agent, status, &screen);
            let changed = self
                .agents
                .get(&pane_id)
                .map(|state| {
                    state.signature != signature || state.agent != agent || state.status != status
                })
                .unwrap_or(true);
            let activity = if changed {
                self.activity = self.activity.wrapping_add(1);
                self.activity
            } else {
                self.agents
                    .get(&pane_id)
                    .map(|state| state.activity)
                    .unwrap_or_default()
            };
            self.agents.insert(
                pane_id,
                AgentState {
                    agent,
                    status,
                    signature,
                    activity,
                },
            );
        }

        self.agents.retain(|pane_id, _| detected.contains(pane_id));
        self.update_terminal_title();
    }

    fn update_terminal_title(&mut self) {
        if self.session_name.is_empty() {
            return;
        }
        let status = self
            .agents
            .values()
            .max_by_key(|state| state.activity)
            .map(|state| state.status);
        let title = match status {
            Some(status) => self.config.format_title(&self.session_name, status),
            None => self.session_name.clone(),
        };
        if self.last_terminal_title.as_deref() != Some(&title) {
            set_terminal_title(Some(title.clone()));
            self.last_terminal_title = Some(title);
        }
    }
}

fn pane_contents_to_string(contents: PaneContents) -> String {
    let viewport_rows = contents.viewport.len();
    let lines = contents
        .lines_above_viewport
        .into_iter()
        .chain(contents.viewport)
        .chain(contents.lines_below_viewport)
        .collect::<Vec<_>>();
    lines[lines.len().saturating_sub(viewport_rows)..].join("\n")
}

fn screen_signature(agent: Agent, status: Status, screen: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    std::mem::discriminant(&agent).hash(&mut hasher);
    std::mem::discriminant(&status).hash(&mut hasher);
    screen.hash(&mut hasher);
    hasher.finish()
}

fn agent_from_command(command: &[String]) -> Option<Agent> {
    let command = command.join(" ").to_ascii_lowercase();
    let has_codex = contains_shell_token(&command, "cx") || contains_shell_token(&command, "codex");
    let has_claude =
        contains_shell_token(&command, "cc") || contains_shell_token(&command, "claude");

    match (has_codex, has_claude) {
        (true, false) => Some(Agent::Codex),
        (false, true) => Some(Agent::Claude),
        _ => None,
    }
}

fn contains_shell_token(input: &str, token: &str) -> bool {
    input
        .split(|character: char| {
            !(character.is_ascii_alphanumeric() || character == '-' || character == '_')
        })
        .any(|part| part == token)
}

fn parse_agent_screen_status(agent: Agent, title: &str, screen: &str) -> Status {
    match agent {
        Agent::Codex => parse_codex_screen_status(title, screen),
        Agent::Claude => parse_claude_screen_status(title, screen),
    }
}

fn parse_codex_screen_status(title: &str, screen: &str) -> Status {
    let lines = recent_non_empty_lines(screen, 40);
    let combined = lines.join("\n");
    let lower = combined.to_ascii_lowercase();

    if lower.contains("press enter to confirm or esc to cancel")
        || lower.contains("enter to submit answer")
        || lower.contains("allow command?")
        || lower.contains("[y/n]")
        || lower.contains("yes (y)")
        || combined.contains("Do you want to run this command?")
        || combined.contains("Do you want to allow this command?")
        || combined.contains("Confirm with number keys")
        || combined.contains("Cancel with Esc")
        || lower.contains("approval required")
        || combined.contains("Would you like to run the following command?")
        || combined.contains("Yes, proceed (y)")
        || combined.contains("No, and tell Codex what to do differently")
        || has_confirmation_prompt(&lower)
    {
        return Status::Waiting;
    }

    if title_starts_with_braille(title)
        || lines.iter().any(|line| {
            let lower_line = line.to_ascii_lowercase();
            line.contains("(Esc to cancel")
                || lower_line.contains("esc to interrupt")
                || lower_line.contains("ctrl+c to interrupt")
        })
        || has_codex_working_header(screen)
    {
        return Status::Working;
    }

    if screen.trim().is_empty() {
        Status::Unknown
    } else {
        Status::Idle
    }
}

fn parse_claude_screen_status(title: &str, screen: &str) -> Status {
    let lower = screen.to_ascii_lowercase();

    if screen.contains("⌕ Search…") {
        return Status::Idle;
    }

    let above = content_above_prompt_box(screen);
    let above_lower = above.to_ascii_lowercase();
    if above_lower.contains("esc to interrupt")
        || above_lower.contains("ctrl+c to interrupt")
        || title_starts_with_braille(title)
        || has_claude_spinner_activity(above)
    {
        return Status::Working;
    }

    if last_prompt_like_line(screen, '❯').is_some_and(|line| !is_numbered_selection_line(line)) {
        return Status::Idle;
    }
    if has_claude_blocked_prompt(screen, &lower) {
        return Status::Waiting;
    }

    if screen.trim().is_empty() {
        Status::Unknown
    } else {
        Status::Idle
    }
}

fn recent_non_empty_lines(content: &str, max_lines: usize) -> Vec<&str> {
    let mut lines = content
        .lines()
        .rev()
        .map(str::trim)
        .filter(|line| !line.is_empty())
        .take(max_lines)
        .collect::<Vec<_>>();
    lines.reverse();
    lines
}

fn title_starts_with_braille(title: &str) -> bool {
    title
        .chars()
        .next()
        .is_some_and(|character| ('\u{2800}'..='\u{28ff}').contains(&character))
}

fn has_codex_working_header(screen: &str) -> bool {
    screen.lines().any(|line| {
        let trimmed = line.trim_start();
        trimmed.starts_with('•') && trimmed.contains("Working (")
    })
}

fn has_confirmation_prompt(lower_content: &str) -> bool {
    if let Some(position) = lower_content
        .find("do you want")
        .or_else(|| lower_content.find("would you like"))
    {
        let after = &lower_content[position..];
        return after.contains("yes") || after.contains('❯');
    }
    false
}

fn has_claude_blocked_prompt(screen: &str, lower_screen: &str) -> bool {
    has_confirmation_prompt(lower_screen)
        || lower_screen.contains("do you want to proceed?")
        || lower_screen.contains("would you like to proceed?")
        || lower_screen.contains("waiting for permission")
        || lower_screen.contains("do you want to allow this connection?")
        || lower_screen.contains("tab to amend")
        || lower_screen.contains("ctrl+e to explain")
        || lower_screen.contains("chat about this")
        || lower_screen.contains("review your answers")
        || lower_screen.contains("skip interview and plan immediately")
        || (has_selection_prompt(screen) && has_claude_yes_no_choice(screen))
        || lower_screen.contains("yes, allow once")
        || lower_screen.contains("yes, allow always")
}

fn has_selection_prompt(screen: &str) -> bool {
    screen.lines().any(is_numbered_selection_line)
}

fn is_numbered_selection_line(line: &str) -> bool {
    let selection = line.trim().trim_start_matches('❯').trim_start();
    selection
        .split_once('.')
        .is_some_and(|(number, _)| !number.is_empty() && number.chars().all(|c| c.is_ascii_digit()))
}

fn has_claude_yes_no_choice(screen: &str) -> bool {
    screen.lines().any(|line| {
        let trimmed = line
            .trim()
            .trim_start_matches('❯')
            .trim_start()
            .to_ascii_lowercase();
        trimmed == "yes"
            || trimmed == "no"
            || trimmed.starts_with("1. yes")
            || trimmed.starts_with("2. no")
            || trimmed.starts_with("yes, and ")
            || trimmed.starts_with("no, and tell claude")
    })
}

fn content_above_prompt_box(screen: &str) -> &str {
    let lines = screen.lines().collect::<Vec<_>>();
    let mut border_count = 0;

    for i in (0..lines.len()).rev() {
        let trimmed = lines[i].trim();
        if !trimmed.is_empty() && trimmed.chars().all(|character| character == '─') {
            border_count += 1;
            if border_count == 2 {
                let byte_offset = lines[..i].iter().map(|line| line.len() + 1).sum::<usize>();
                return &screen[..byte_offset.min(screen.len())];
            }
        }
    }
    screen
}

fn has_claude_spinner_activity(screen: &str) -> bool {
    const SPINNER_CHARS: &str = "·✱✲✳✴✵✶✷✸✹✺✻✼✽✾✿❀❁❂❃❇❈❉❊❋✢✣✤✥✦✧✨⊛⊕⊙◉◎◍⁂⁕※⍟☼★☆";
    screen.lines().any(|line| {
        let trimmed = line.trim();
        let mut characters = trimmed.chars();
        if let Some(first) = characters.next() {
            let rest = characters.collect::<String>();
            return SPINNER_CHARS.contains(first)
                && rest.starts_with(' ')
                && rest.contains('\u{2026}')
                && rest.chars().any(char::is_alphanumeric);
        }
        false
    })
}

fn last_prompt_like_line(screen: &str, prompt: char) -> Option<&str> {
    screen
        .lines()
        .rev()
        .map(str::trim)
        .find(|line| !line.is_empty() && !is_claude_footer_line(line) && line.starts_with(prompt))
}

fn is_claude_footer_line(line: &str) -> bool {
    line.starts_with('?')
        || line.starts_with('>')
        || line.starts_with('◯')
        || line.contains("esc to interrupt")
        || line.contains("ctrl+c to interrupt")
        || line.contains("tokens")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn detects_wrapped_agents() {
        assert_eq!(
            agent_from_command(&["nono".into(), "run".into(), "--".into(), "codex".into()]),
            Some(Agent::Codex)
        );
        assert_eq!(
            agent_from_command(&["nono".into(), "run".into(), "--".into(), "claude".into()]),
            Some(Agent::Claude)
        );
    }

    #[test]
    fn reads_title_configuration() {
        let config = PluginConfig::from_map(&BTreeMap::from([
            ("terminal_title".into(), "[{session}] {agent_status}".into()),
            ("agent_status_working".into(), "W".into()),
        ]));
        assert_eq!(config.format_title("main", Status::Working), "[main] W");
    }

    #[test]
    fn parses_waiting_and_running_states() {
        assert_eq!(
            parse_codex_screen_status("codex", "Do you want to run this command?\n❯ 1. Yes"),
            Status::Waiting
        );
        assert_eq!(
            parse_claude_screen_status("claude", "✻ Working…\nesc to interrupt"),
            Status::Working
        );
    }

    #[test]
    fn ignores_stale_waiting_prompts_when_claude_is_idle() {
        let screen = "Do you want to proceed?\n❯ 1. Yes\nTask complete\n❯";
        assert_eq!(parse_claude_screen_status("claude", screen), Status::Idle);
    }

    #[test]
    fn uses_live_viewport_while_scrolled_up() {
        let contents = PaneContents {
            lines_above_viewport: vec!["Do you want to proceed?".into()],
            viewport: vec!["❯ 1. Yes".into(), "old output".into(), "more output".into()],
            lines_below_viewport: vec!["Task complete".into(), "".into(), "❯".into()],
            ..Default::default()
        };
        assert_eq!(pane_contents_to_string(contents), "Task complete\n\n❯");
    }
}
