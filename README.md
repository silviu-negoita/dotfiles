# Silviu's dotfiles

Personal shell, Git, Ruby, and Vim configuration for macOS and Linux. The
repository keeps the day-to-day commands in version control while leaving
machine-specific settings and secrets outside Git.

## Requirements

- Zsh
- Git
- Ruby and Rake
- Vim (optional, but required by `rake check`)
- `fzf` for the interactive shell helpers

Oh My Zsh and the two external Zsh plugins are installed on demand:
`zsh-autosuggestions` and `zsh-syntax-highlighting`.

## Install

```sh
git clone https://github.com/silviu-negoita/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
rake install
```

The installer is interactive and idempotent:

- existing managed links are left alone;
- changed targets are replaced only after confirmation;
- replaced files are moved under `~/.dotfiles-backups/<timestamp>/`;
- `~/.zshrc` is copied, preserving the historical behavior of this repo;
- generated `~/.gitconfig` has mode `0600`;
- `README.md` and `LICENSE` are no longer installed as accidental dotfiles.

Run the diagnostics without changing the machine:

```sh
rake doctor
```

## Local configuration and secrets

`zshrc` loads `~/.zshrc.local` when it exists. Put machine-specific paths and
non-public configuration there, and keep the file outside this repository:

```sh
touch ~/.zshrc.local
chmod 600 ~/.zshrc.local
```

Do not store API keys, passwords, or access tokens in this repository. Prefer a
credential manager or a dedicated secrets CLI; if environment variables are
unavoidable, keep them in the local file with restrictive permissions.

The repository also installs `my_aliases.sh` and `my_functions.sh` as
`~/.my_aliases.sh` and `~/.my_functions.sh`.

## Validation

```sh
rake check
```

This runs the Ruby tests and syntax checks for Ruby, Bash, Zsh, and Vim files.
No network access or changes to the home directory are made by the check.

## Vim compatibility

The Vim directory still contains the legacy vendored plugins used by the
existing `vimrc`. They are intentionally kept in place so an update does not
silently remove commands or mappings. New Vim dependencies should use native
packages under `vim/pack/*/start`; see Vim's `:help packages`.

## Workstation helper

`workstation_setup.sh` contains the small GNOME-specific setup. It exits cleanly
on macOS and other systems without `gsettings`.

## License and history

This repository started as a fork of Ryan Bates' dotfiles. The original MIT
license is retained in `LICENSE`; the current configuration and installer have
since diverged substantially.
