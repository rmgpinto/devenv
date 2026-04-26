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
- claude-code
