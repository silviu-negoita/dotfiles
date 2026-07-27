#!/usr/bin/env zsh

# This file is sourced by zsh; keep machine-specific overrides in ~/.zshrc.local.
export PROJECTS_PATH="${PROJECTS_PATH:-$HOME/projects}"
export GITLAB_BASE_URL="${GITLAB_BASE_URL:-https://gitlab.com/signicat/orange-stack/self-service/my-signicat/-/tree/}"
export IDEA_PATH="${IDEA_PATH:-}"

# Common helpers
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

yankpwd() {
  print -rn -- "$PWD" | copy_to_clipboard &&
    print "Copied to clipboard: $PWD"
}

reloadshell() {
  print "Reloading shell"
  exec "${SHELL:-/bin/zsh}" -l
}

my_aliases() {
  "${EDITOR:-vim}" "$HOME/.my_aliases.sh"
}

alias mvnc='mvn clean install -DskipTests -DskipITs -T03.C'

alias mvnsy='cp ~/.m2/settings.y.xml ~/.m2/settings.xml'
alias mvnsd='cp ~/.m2/settings.d.xml ~/.m2/settings.xml'

alias mvni='mvn install -DskipTests -DskipITs -T03.C'
mvnd() {
  mvn dependency:tree | "${PAGER:-less}"
}



alias homelab-pi='ssh silviun@homelab-pi'
alias homelab-green='ssh silviun@hass.green.silviun.net'
alias homelab-main='ssh silviun@homelab-main'

alias java21='export JAVA_HOME=$(/usr/libexec/java_home -v 21)'
alias java25='export JAVA_HOME=$(/usr/libexec/java_home -v 25)'

# Install or update fzf without deleting an existing checkout.
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

gitcleanlocal() {
  local -a branches
  branches=("${(@f)$(git branch -vv | awk '/origin\/.*: gone]/{print $1}')}")
  (( ${#branches} )) && git branch -D -- "${branches[@]}"
}
alias gitcleanremote='git remote prune origin'

# funny
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

alias omessenger='open https://messenger.com'
alias owhatsapp='open https://web.whatsapp.com'
alias ogitflux='open https://gitlab.com/signicat/orange-stack/self-service'

obranch() {
  local project_relative_path project_absolute_path branch_name gitlab_url
  project_relative_path="$(find "$PROJECTS_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | fzf)" ||
    return 1
  [[ -n "$project_relative_path" ]] || return 1
  project_absolute_path="$PROJECTS_PATH/$project_relative_path"
  branch_name="$(getbranchname "$project_absolute_path")" || return 1
  gitlab_url="https://gitlab.com/signicat/orange-stack/self-service/${project_relative_path}/-/tree/${branch_name}"
  open "$gitlab_url"
}

omergerequests() {
  local project_relative_path
  project_relative_path="$(find "$PROJECTS_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | fzf)" ||
    return 1
  [[ -n "$project_relative_path" ]] || return 1

  open "https://gitlab.com/signicat/orange-stack/self-service/${project_relative_path}/-/merge_requests"
}


dl() {
  docker logs -f "$1"
}

dr() {
  docker restart "$1"
}

drl() {
  dr "$1"
  dl "$1"
}

docker-cleanup() {
  local -a containers
  containers=("${(@f)$(docker ps -aq)}")
  if (( ! ${#containers} )); then
    print "No containers to remove."
    return
  fi

  print "Stopping..."
  docker stop -- "${containers[@]}"
  print "Removing..."
  docker rm -- "${containers[@]}"
}

dc() {
  docker-cleanup
}


killport() {
  local -a pids
  pids=("${(@f)$(sudo lsof -t -i:"$1")}")
  if (( ! ${#pids} )); then
    print "No process is listening on port $1."
    return 1
  fi
  sudo kill -9 -- "${pids[@]}"
}

# show clipboard
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



ogitpipeline() {
  if [[ -z "${GITLAB_URL:-}" ]]; then
    print -u2 "Please specify GITLAB_URL in ~/.zshrc.local."
    return 1
  fi
  if [[ -z "${GITLAB_PRIVATE_TOKEN:-}" ]]; then
    print -u2 "Please provide GITLAB_PRIVATE_TOKEN through a credential manager."
    return 1
  fi
}

myip() {
  local public_ip
  public_ip="$(curl --fail --silent --show-error https://api.ipify.org)" ||
    return 1
  print -rn -- "$public_ip" | copy_to_clipboard || return 1

  print "Public IP address copied to clipboard: $public_ip"
}

greet_user() {
  print "Hello, $USER!"
}

# Yellow stack aliases

alias yvpn='netbird service start && netbird up'

