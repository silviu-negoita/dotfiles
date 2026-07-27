#!/usr/bin/env zsh

export PROJECTS_PATH="${PROJECTS_PATH:-$HOME/projects}"
export IDEA_PATH="${IDEA_PATH:-}"

typeset -U path PATH
[[ -d "$DOTFILES_DIR/scripts" ]] && path=("$DOTFILES_DIR/scripts" $path)

copy_to_clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard
  else
    print -u2 "No clipboard command found (pbcopy, wl-copy, or xclip)."
    return 1
  fi
}

showclip() {
  if command -v pbpaste >/dev/null 2>&1; then
    pbpaste
  elif command -v wl-paste >/dev/null 2>&1; then
    wl-paste
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard -o
  else
    print -u2 "No clipboard command found (pbpaste, wl-paste, or xclip)."
    return 1
  fi
}

yankpwd() {
  print -rn -- "$PWD" | copy_to_clipboard &&
    print "Copied to clipboard: $PWD"
}

myip() {
  local public_ip
  public_ip="$(curl --fail --silent --show-error https://api.ipify.org)" ||
    return 1
  print -rn -- "$public_ip" | copy_to_clipboard || return 1
  print "Public IP address copied to clipboard: $public_ip"
}

netspeed() {
  local speedtest_binary
  if command -v networkQuality >/dev/null 2>&1; then
    networkQuality "$@"
  elif speedtest_binary="$(whence -p speedtest 2>/dev/null)" &&
       [[ -n "$speedtest_binary" ]]; then
    "$speedtest_binary" "$@"
  elif speedtest_binary="$(whence -p speedtest-cli 2>/dev/null)" &&
       [[ -n "$speedtest_binary" ]]; then
    "$speedtest_binary" "$@"
  else
    print -u2 "No speed-test tool found (networkQuality, speedtest, or speedtest-cli)."
    return 1
  fi
}

alias speedtest='netspeed'

open_url() {
  if [[ "$OSTYPE" == darwin* ]]; then
    command open "$@"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$@" >/dev/null 2>&1 &
  elif command -v gio >/dev/null 2>&1; then
    gio open "$@" >/dev/null 2>&1 &
  else
    print -u2 "No URL opener found (open, xdg-open, or gio)."
    return 1
  fi
}

reloadshell() {
  print "Reloading shell"
  exec "${SHELL:-/bin/zsh}" -l
}

dotedit() {
  "${EDITOR:-vim}" "$DOTFILES_DIR/zsh"
}

# Compatibility for the historical command name.
my_aliases() {
  dotedit
}

c() {
  builtin cd -- "$PROJECTS_PATH/${1:-}"
}

_c() {
  _files -W "$PROJECTS_PATH" -/
}
(( $+functions[compdef] )) && compdef _c c

# Select a directory recursively. Pass -a to include hidden directories.
cdf() {
  local include_hidden=0 root="." directory
  if [[ "${1:-}" == "-a" ]]; then
    include_hidden=1
    shift
  fi
  root="${1:-.}"

  if [[ ! -d "$root" ]]; then
    print -u2 "Not a directory: $root"
    return 1
  fi

  if (( include_hidden )); then
    directory="$(find "$root" -type d 2>/dev/null | fzf +m)" || return 1
  else
    directory="$(
      find "$root" -path '*/.*' -prune -o -type d -print 2>/dev/null | fzf +m
    )" || return 1
  fi

  [[ -n "$directory" ]] && builtin cd -- "$directory"
}

fop() {
  local file
  file="$(fzf --query="${1:-}" --select-1 --exit-0)" || return 1
  [[ -n "$file" ]] && open_url "$file"
}

# Intentionally forceful: these helpers are for terminating stuck processes.
fkill() {
  local signal="${1:-9}"
  local -a pids
  pids=("${(@f)$(ps -axo pid=,user=,command= | fzf -m | awk '{print $1}')}")
  (( ${#pids} )) && sudo kill "-$signal" -- "${pids[@]}"
}

killport() {
  local port="${1:-}"
  local -a pids

  if [[ "$port" != <-> ]] || (( port < 1 || port > 65535 )); then
    print -u2 "Usage: killport <1-65535>"
    return 2
  fi

  pids=("${(@f)$(sudo lsof -t -nP -iTCP:"$port" -sTCP:LISTEN)}")
  if (( ! ${#pids} )); then
    print "No process is listening on port $port."
    return 1
  fi
  sudo kill -9 -- "${pids[@]}"
}

installfzf() {
  if [[ -d "$HOME/.fzf/.git" ]]; then
    git -C "$HOME/.fzf" pull --ff-only
  elif [[ -e "$HOME/.fzf" ]]; then
    print -u2 "$HOME/.fzf exists and is not a Git checkout; leaving it unchanged."
    return 1
  else
    git clone https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi

  "$HOME/.fzf/install"
}

yoloc() {
  local message
  message="$(curl --fail --silent --show-error https://whatthecommit.com/index.txt)" ||
    return 1
  git commit -m "$message" >/dev/null
}

yolom() {
  local random_message
  random_message="$(curl --fail --silent --show-error https://whatthecommit.com/index.txt)" ||
    return 1
  print -rn -- "$random_message" | copy_to_clipboard || return 1
  print "'${random_message}' copied to clipboard."
}

aliashelp() {
  command cat <<'EOF'
Aliasuri shell:
  mvnc              Maven clean install, fără teste
  mvni              Maven install, fără clean și fără teste
  mvnsy / mvnsd     activează setările Maven Yellow / default
  hl-pi             SSH pe Raspberry Pi
  hl-green          SSH pe Home Assistant Green
  hl-main           SSH pe serverul homelab principal
  java21 / java25   selectează rapid versiunea de Java pe macOS
  yvpn              pornește serviciul și conexiunea NetBird
  dobuild           construiește imaginea Docker din directorul curent
  doimages          listează imaginile Docker
  dops / dopsa      listează containerele active / toate containerele
  gitcleanremote    elimină referințele remote Git dispărute
  speedtest         testează rapid viteza conexiunii

Aliasuri Git (folosește `git <alias>`):
  git co            checkout
  git sw            switch
  git rs            restore
  git st            status scurt, cu branch
  git lg            istoric compact sub formă de graf

Pentru expandarea exactă a unui alias shell: alias <nume>
EOF
}

dothelp() {
  command cat <<'EOF'
Navigation:
  c [project]                 cd into $PROJECTS_PATH
  cdf [-a] [directory]       select a directory with fzf
  fop [query]                select and open a path

Shell:
  dotedit                    edit the managed Zsh modules
  aliashelp                  explain the managed aliases
  reloadshell                replace the current login shell
  yankpwd / showclip / myip  clipboard helpers
  fkill [signal]             select processes and sudo kill (defaults to -9)
  killport <port>            sudo kill -9 the listener on a TCP port
  installfzf                 install or update ~/.fzf
  yoloc / yolom              random commit message helpers

Git:
  fgb / fgc / fgt            select a branch, commit, or tag
  gitcleanlocal              delete local branches with gone upstreams
  gitcleanremote             prune remote-tracking branches
  gitlab-open [action]       open repo, branch, MRs, or pipelines

Docker:
  dl / dr / drl              logs, restart, restart-and-logs
  da / ds                    select a container to attach or stop
  dc                         stop and remove every local container
  dops / dopsa / doimages    common Docker listings

Work:
  mvnc / mvni / mvnd         Maven build and dependency helpers
  mvn-settings <y|d>         select a managed Maven settings file
  mvnsy / mvnsd              compatibility aliases for mvn-settings
  use-java <version>         select a macOS JDK
  java21 / java25            common JDK selections
  yvpn                       start and connect NetBird
  pitemp [host] [seconds]    monitor Raspberry Pi temperature
  pistatus [host]            show Raspberry Pi health
  kwhere                     show Kubernetes context and namespace
  kuse [context] [namespace] safely switch Kubernetes target
EOF
}

if [[ -o interactive ]]; then
  insert_sudo() {
    zle beginning-of-line
    zle -U "sudo "
  }
  zle -N insert-sudo insert_sudo
  bindkey "^[s" insert-sudo
fi
