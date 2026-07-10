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

Secrets are defined in 1Password and synced to env vars via `env/`:

1. Define each secret as a 1Password item.
2. List it in `env/secrets`: `<store>  <name>  <op://reference>  <1password-account>`, where `<store>` is `nono` (exposed to the AI sandbox) or `mise` (host mise only).
3. Reference it (or any non-secret var) in the relevant scope template — `env/work.mise.toml`, `env/personal.mise.toml`, or `env/user.mise.toml` (user-global, loaded in every shell regardless of cwd). Secrets exposed to the AI sandbox are mapped to env vars by their `nono-<name>` keychain account in the nono `ai` profile (`dotfiles/nono/.config/nono/profiles/ai.json`, `env_credentials`).
4. Run `env/setup.sh` (also run by `./devenv.sh`).

`env/setup.sh` pulls each secret from its 1Password account (`op read --account`), caches it in the macOS keychain (service `<store>`, account `<store>-<name>`), and copies the mise scope templates. The mise files resolve secrets from the keychain at load time, and the nono `ai` profile (stowed by `dotfiles/setup.sh`) resolves its `env_credentials` from the keychain at sandbox startup — no plaintext secret is written to disk.

Caching in the keychain avoids `op read`'s latency on every shell/mise load:

Secrets are cached under one of two services — `nono` for AI-sandbox secrets,
`mise` for host mise-only secrets — with each account prefixed by its store
(`nono-...` / `mise-...`). Host `mise` secrets are added with `-A`;
AI-sandbox `nono` secrets are granted to the real `nono` binary with `-T` when
created. Existing items keep their ACLs during normal syncs; set
`REFRESH_NONO_KEYCHAIN_ACL=1` for a deliberate repair after a `nono` reinstall
or upgrade:

```
# add host mise secret to keychain
security add-generic-password -a mise-name-of-my-secret -s mise -w <secret> -A

# repair existing nono secret ACL, trusting the actual nono binary
security add-generic-password -a nono-name-of-my-secret -s nono -w <secret> -U -T "$(mise which nono)"

# read secret from keychain
security find-generic-password -a <store>-name-of-my-secret -s <store> -w

# delete secret from keychain
security delete-generic-password -a <store>-name-of-my-secret -s <store>
```

Use `REFRESH_NONO_KEYCHAIN_ACL=1` only when `cc` or `cx` prompts for Keychain
access to `nono-*` secrets after `nono` was reinstalled or upgraded. Do not use
it for normal `./devenv.sh` runs; it intentionally rewrites Keychain ACLs and
macOS may prompt once per `nono-*` item.
