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
- Docker, `glab`, Maven, NetBird, and macOS JDKs for their respective helpers

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

The maintained shell configuration lives in four focused modules:

- `zsh/core.zsh` — navigation, clipboard, process, and shell helpers;
- `zsh/git.zsh` — Git cleanup and `fzf` selectors;
- `zsh/docker.zsh` — the small Docker command set;
- `zsh/work.zsh` — Maven, Java, GitLab, VPN, and homelab helpers.

The installer links the directory as `~/.zsh`. It also retains
`~/.my_aliases.sh` and `~/.my_functions.sh` as compatibility loaders for old
shell configurations and scripts. New code should source `~/.zsh/load.zsh`
instead.

Run `dothelp` for the concise command reference. The most frequently used
compatibility names (`mvnc`, `mvnsy`, `mvnsd`, `dc`, and `gitcleanremote`) are
preserved.

### Destructive helpers

The following commands are intentionally forceful:

- `dc` stops and removes every local Docker container;
- `fkill` selects processes and runs `sudo kill -9` by default;
- `killport` runs `sudo kill -9` on the process listening on the requested
  TCP port.

Use them only when the broad scope is intended. `gitcleanlocal` is safer: it
previews local branches whose upstream is gone and asks for confirmation.

### GitLab and local tools

`gitlab-open [repo|branch|mrs|pipelines] [repository]` replaces the old
hard-coded GitLab project helpers. It uses the repository's `origin` and
`glab`, so no private token is stored in these files.

`pitemp` monitors the temperature of `silviun@homelab-pi` once per second.
Use `pitemp <host> <seconds>` for another Raspberry Pi, set `PI_TEMP_HOST` in
`~/.zshrc.local` to change the default, or run `pitemp local` directly on a Pi.

`tagversions` is installed from `scripts/`. The old `rbates` plugin path is
kept as a compatibility shim for existing installations, but no longer
defines aliases and is not activated by the managed `zshrc`.

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
