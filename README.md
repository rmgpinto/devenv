# DevEnv

This is my personal development environment (DevEnv) to setup my computer from scratch.
Instructions are below.

## Clone this repo and run setup

```bash
mkdir -p dev/work
mkdir -p dev/personal && cd $_
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
4. Copy `config/alacritty/Alacritty.incs`, in Finder, go to `Applications`, right-click on Alacritty, `Get Info` and paste on application icon.
5. Follow 1Password SSH agent [instructions](https://developer.1password.com/docs/ssh/get-started#step-3-turn-on-the-1password-ssh-agent)

## Notes
Due to 1Password CLI being slow (`op read`), I've used the following:

```
# add secret to keychain
security add-generic-password -a “${USER}” -s name-of-my-secret -w

# read secret from keychain
security find-generic-password -a “${USER}” -s name-of-my-secret -w

# delete secret from keychain
security delete-generic-password -a “${USER}” -s name-of-my-secret
```

