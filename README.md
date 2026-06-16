# DevEnv

This is my personal development environment (DevEnv) to setup my computer from scratch.
Instructions are below.

## Clone this repo and run setup

```bash
mkdir -p /Users/Shared/dev/work
mkdir -p /Users/Shared/dev/personal && cd $_
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

Secrets are defined in 1Password and synced to env vars via `env/`:

1. Define each secret as a 1Password item.
2. List it in `env/secrets`: `<keychain-service>  <op://reference>  <host|sandbox|both>  <1password-account>`.
3. Reference it (or any non-secret var) in the relevant scope template — `env/ai-sandbox.mise.toml`, `env/work.mise.toml`, `env/personal.mise.toml`, or `env/main-user.mise.toml` (main-user-global, loaded in every main-user shell regardless of cwd).
4. Run `env/setup.sh` (also run by `./devenv.sh`).

`env/setup.sh` pulls each secret from its 1Password account (`op read --account`), caches it in the macOS keychain (host and/or the `ai-sandbox` user's keychain), and copies the scope templates to their destinations (`~ai-sandbox/.config/mise/config.toml`, `/Users/Shared/dev/work/.mise.toml`, `/Users/Shared/dev/personal/.mise.toml`, `~/.config/mise/conf.d/devenv.toml`). The `.mise.toml` files resolve secrets from the keychain at mise load time via `{{ exec(command='security find-generic-password …') }}` — no plaintext secret is written to disk.

Caching in the keychain avoids `op read`'s latency on every shell/mise load:

```
# add secret to keychain
security add-generic-password -a "${USER}" -s name-of-my-secret -w <secret>

# read secret from keychain
security find-generic-password -a "${USER}" -s name-of-my-secret -w

# delete secret from keychain
security delete-generic-password -a "${USER}" -s name-of-my-secret
```

