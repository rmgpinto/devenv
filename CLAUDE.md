# Sandbox

You are running as the `ai-sandbox` macOS user — a restricted user dedicated to AI agents. Boundaries:

- **Writable:** `/Users/Shared/dev` (this workspace) and `/Users/ai-sandbox` (sandbox home).
- **No access:** the host user's home (`/Users/rmgpinto`) or any other user directory.
- **No sudo, no system modification, no mounted/network drives.**

Host-app configs (Ghostty, zsh, git, nvim, k9s, lazygit, starship, ssh, gh, claude, …) are reachable: their source files live in `personal/devenv/dotfiles/<app>/` and the user stows them into `~/` via `personal/devenv/dotfiles/setup.sh`. The directory layout under each app mirrors its target path under `$HOME` — e.g. Ghostty's config is at `personal/devenv/dotfiles/ghostty/.config/ghostty/config`, which stow links to `~/.config/ghostty/config`. To change a host config, edit the file under `dotfiles/` — never touch `~/.config/...` directly (it's outside the sandbox anyway, and any change there would be clobbered on the next stow).

# Workspace layout

`/Users/Shared/dev` is a container for many independent repos, not a single project:

- `personal/` — personal projects
- `work/` — work projects

Each subdirectory is its own repo with its own conventions. When working in one, treat that subdirectory as the project root and look for its own `CLAUDE.md`, `README`, and config.

# Worktrees

Repos in this workspace may use git worktrees under `<repo>/.worktrees/<branch>/` for active branch work; the top-level checkout typically stays on `main`. Before editing any file in a repo:

1. Run `git worktree list` from the repo root to see active worktrees.
2. If a worktree exists that matches the task at hand, `cd` into it and edit there. Do not edit the top-level checkout unless the user has explicitly said to.
3. If multiple worktrees could apply, or none clearly does, ask before writing.

## Delegating work to another repo

To hand a task to a fresh agent on a *different* repo, prepare a worktree there and seed its prompt with `bin/wt-spawn` (the non-interactive guts of `bin/wt`):

```
/Users/Shared/dev/personal/devenv/bin/wt-spawn <repo> <branch> --prompt "<task for the sub-agent>"
```

It clones/pulls the repo under `work/`, creates the worktree, and seeds `.wt-claude-prompt`, printing the worktree's absolute path on stdout. It does **not** open the zellij session: that server is owned by the host user and the agent (running as `ai-sandbox`) can't reach its socket. So `wt-spawn` ends by printing a handoff line — surface it to the user verbatim:

```
wt-here <path>
```

When the user runs `wt-here` in their own shell, `zcode` spawns the session and its claude pane reads the seeded prompt, starting the sub-agent on the task. Use `--from-pr` to base the worktree on an existing PR branch.

# This file

The source-of-truth is `personal/devenv/CLAUDE.md`. `/Users/Shared/dev/CLAUDE.md` is a symlink to it (set up by `personal/devenv/ai/setup.sh`), so any Claude instance launched anywhere under `/Users/Shared/dev` discovers these instructions via the parent-directory walk. `/Users/Shared/dev/.mise.toml` is separately stowed from `personal/devenv/ai/sb/.mise.toml`.

# Environment

`mise` is installed and available. Tools provisioned via `.mise.toml`:

- node, pnpm, yarn
- ruby, python3
- sqlite
- jq, yq
- ripgrep
- k6
- gh (authenticated via `GH_TOKEN`)
- claude-code
