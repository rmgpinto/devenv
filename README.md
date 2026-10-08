# DevEnv

This is my personal development environment (DevEnv) to setup my computer from scratch.
Instructions are below.

## Clone this repo and run setup

```bash
mkdir -p ~/dev/work
mkdir -p ~/dev/personal && cd $_
git clone https://github.com/rmgpinto/devenv.git
cd devenv
./devenv.sh setup
```

## Setup
1. Login 1Password
2. Setup 1Password CLI
```bash
op account add --address my.1password.com --signin
```
3. Load `config/raycast/raycast.rayconfig` into Raycast
4. Follow 1Password SSH agent [instructions](https://developer.1password.com/docs/ssh/get-started#step-3-turn-on-the-1password-ssh-agent)
5. Download [AppCleaner](https://freemacsoft.net/appcleaner/)

## Secrets & env vars

AI secrets are configured directly in
`dotfiles/nono/.config/nono/profiles/ai.json` using native 1Password references:

```json
{
  "env_credentials": {
    "op://Employee/GitHub - AI read-only expires 25-04-2027/token": "GH_TOKEN"
  }
}
```

`cc` and `cx` call nono directly. Nono resolves `op://` references through the
1Password CLI before starting the sandbox. The launchers select the work account
through `OP_ACCOUNT`, with an inherited value taking precedence. Enable
1Password desktop CLI integration and Touch ID to authorize access.

To add or change an AI secret reference, edit the profile. Secret value changes
in 1Password need no sync. The profile is stowed by `dotfiles/setup.sh`.

The launchers unset inherited `GH_TOKEN` and `GITHUB_TOKEN` before starting nono.
Nono loads `GH_TOKEN` from the read-only GitHub item shown above, and `gh` uses
it directly. `GITHUB_TOKEN` is not injected or aliased. AI GitHub credentials
always come from 1Password, with no host environment fallback.

There is no custom credential helper, external `op run` wrapper, AI Keychain
cache, nono signing, or ACL repair. Old cached AI Keychain items and the signing
identity are unused; setup does not delete them.

Host mise secrets remain in `env/secrets`, with columns
`<store> <name> <op://reference> <account>`. References may contain spaces.
`env/setup.sh` syncs them to the host Keychain and installs the mise scope
templates. Run it after changing a host secret or scope template. No plaintext
secrets are stored in the repository.
