# Sandbox

AI agents run as the host user under the nono `ai` profile. Boundaries:

- **Writable:** `~/dev` (this workspace) and explicit agent state dirs such as `~/.config/claude`, `~/.config/codex`, and nono/mise caches.
- **No access:** the rest of the host home or any other user directory unless the nono profile grants it.
- **No sudo, no system modification, no mounted/network drives.**

Host-app configs (Ghostty, zsh, git, nvim, k9s, lazygit, starship, ssh, gh, claude, …) are reachable: their source files live in `personal/devenv/dotfiles/<app>/` and the user stows them into `~/` via `personal/devenv/dotfiles/setup.sh`. The directory layout under each app mirrors its target path under `$HOME` — e.g. Ghostty's config is at `personal/devenv/dotfiles/ghostty/.config/ghostty/config`, which stow links to `~/.config/ghostty/config`. To change a host config, edit the file under `dotfiles/` — never touch `~/.config/...` directly (it's outside the sandbox anyway, and any change there would be clobbered on the next stow).

# Workspace layout

`~/dev` is a container for many independent repos, not a single project:

- `personal/` — personal projects
- `work/` — work projects

Each subdirectory is its own repo with its own conventions. When working in one, treat that subdirectory as the project root and look for its own `AGENTS.md`, `README`, and config.

# Worktrees

Repos in this workspace may use git worktrees under `<repo>/.worktrees/<branch>/` for active branch work; the top-level checkout typically stays on `main`. Before editing any file in a repo:

1. Run `git worktree list` from the repo root to see active worktrees.
2. If a worktree exists that matches the task at hand, `cd` into it and edit there. Do not edit the top-level checkout unless the user has explicitly said to.
3. If multiple worktrees could apply, or none clearly does, ask before writing.

## Delegating work to another repo

To hand a task to a fresh agent on a *different* repo, prepare a worktree there and seed its prompt with `bin/wt-spawn` (the non-interactive guts of `bin/wt-new`):

```
~/dev/personal/devenv/bin/wt-spawn <repo> <branch> --prompt "<task for the sub-agent>"
```

It clones/pulls the repo under `work/`, creates the worktree, and seeds `.wt-claude-prompt`, printing the worktree's absolute path on stdout. It does **not** open the zellij session. So `wt-spawn` ends by printing a handoff line — surface it to the user verbatim:

```
wt go <path>
```

When the user runs `wt go <path>` in their own shell, `zcode` spawns the session and its agent pane reads the seeded prompt, starting the sub-agent on the task. Use `--from-pr` to base the worktree on an existing PR branch.

# This file

The source-of-truth is `personal/devenv/AGENTS.md`. `~/dev/AGENTS.md` is a symlink to it, created by `personal/devenv/dotfiles/setup.sh`, so agents launched anywhere under `~/dev` discover these instructions through the parent-directory walk.

# Git commits

Before creating a commit, always run `git config commit.template` in the current directory. If a template is configured, read it and use its structure as the exact blueprint for the commit message, including when supplying a message with `-m` or `-F`.

Fill all required placeholders, tags, and section headers using the staged changes and available task context. Preserve every template section and its formatting unless explicitly instructed otherwise. If required context such as a Linear URL is missing, ask rather than inventing it.

The work commit template is enabled through `includeIf` only for repositories under `~/dev/work/` and its subdirectories. Work commit subjects start with a verb such as `Added`, `Created`, `Changed`, `Fixed`, or `Removed`. The body contains `ref <linear-url>`, a blank line, and at least one bullet explaining the changes. Add as many bullets as needed; there is no maximum. Keep commits small and atomic, with each commit covering one coherent change. Template comments are guidance and should not appear in the final commit message.

# Secrets & env vars

AI secrets use **nono native `op://` references → 1Password CLI → sandbox env**.
Host mise secrets use **1Password → macOS Keychain → per-scope mise templates**.

- `dotfiles/nono/.config/nono/profiles/ai.json` — AI secret references live directly in `env_credentials`, mapping an `op://<vault>/<item>/<field>` URI to its environment variable. Non-secret vars live in `environment.set_vars`. Stow profile changes through `dotfiles/setup.sh`; never edit `~/.config/nono` directly.
- `cc` and `cx` call nono directly and select the work 1Password account through `OP_ACCOUNT`, preserving an inherited override. Nono resolves references through `op read` before applying the sandbox. No credential helper or external `op run` wrapper is used.
- `cc` and `cx` unset inherited `GH_TOKEN` and `GITHUB_TOKEN` before starting nono. The profile maps `op://Employee/GitHub - AI read-only expires 25-04-2027/token` directly to `GH_TOKEN`. `gh` uses that read-only token; `GITHUB_TOKEN` is not injected or aliased. Never source AI GitHub credentials from the host environment.
- `env/secrets` — host-only manifest with columns `<store> <name> <op://reference> <account>`. References may contain spaces; store is `mise`. No plaintext secrets are stored here.
- `env/setup.sh` — caches host secrets in Keychain (service `mise`, account `mise-<name>`) and installs `env/{work,personal,user}.mise.toml` templates. It does not cache AI secrets or sign nono.

To add or change an AI secret reference, edit the profile. Changes to values in 1Password need no sync. Enable 1Password desktop CLI integration and Touch ID for authorization. For host mise secrets or scoped vars, update the manifest/templates and re-run `env/setup.sh`.

Old cached AI Keychain entries and the signing identity are unused; setup does not delete them. There are no nono signing or Keychain ACL repair steps.

Work vs personal env vars are **directory-scoped** — `work/.mise.toml` loads only under `work/`, `personal/.mise.toml` only under `personal/`. Vars that must be available everywhere regardless of cwd, e.g. at the `~/dev` root, go in `user.mise.toml` instead, which mise loads globally from `~/.config/mise/conf.d/`.

# Environment

`mise` and `nono` are installed and available. AI env vars are defined in the nono `ai` profile (`dotfiles/nono/.config/nono/profiles/ai.json`):

- node, pnpm, yarn
- ruby, python3
- sqlite
- jq, yq
- ripgrep
- k6
- Read-only gh token available as `GH_TOKEN` from the nono profile’s `op://` reference
- read-only Google Cloud access is available through `~/dev/personal/devenv/bin/gcloud-ai`
- claude-code

# Kubernetes

Agents have read-only filesystem access to these kubeconfigs through the nono `ai` profile:

| Cluster | Kubeconfig |
| --- | --- |
| `prd-k8s-01` (production) | `~/.kube-ai/prd-k8s-01-ai-agent.yaml` |
| `stg-k8s-01` (staging) | `~/.kube-ai/stg-k8s-01-ai-agent.yaml` |
| `sup-k8s-01` | `~/.kube-ai/sup-k8s-01-ai-agent.yaml` |

For cluster debugging, use the kubeconfigs above. Never use `~/.kube/config`, the host's default context, or bare `kubectl` commands. Always select `prd`, `stg`, or `sup` explicitly with `--kubeconfig` on every command. If the requested cluster is unclear, ask which cluster to inspect.

Examples:

```sh
kubectl --kubeconfig="$HOME/.kube-ai/prd-k8s-01-ai-agent.yaml" get pods -A
kubectl --kubeconfig="$HOME/.kube-ai/stg-k8s-01-ai-agent.yaml" get pods -A
kubectl --kubeconfig="$HOME/.kube-ai/sup-k8s-01-ai-agent.yaml" get pods -A
```

Use these credentials for read-only cluster inspection. Kubernetes RBAC enforces cluster permissions; nono's read-only file access only protects the kubeconfig files. Do not modify the kubeconfigs or switch the host's default context.
