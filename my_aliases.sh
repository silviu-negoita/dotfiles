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

alias fan-turbo='cd /sys/devices/platform/asus-nb-wmi; sudo sh -c "echo 1 >> throttle_thermal_policy"; source ~/.zshrc; cd ~;'
alias fan-performance='cd /sys/devices/platform/asus-nb-wmi; sudo sh -c "echo 0 >> throttle_thermal_policy"; source ~/.zshrc; cd ~;'
alias fan-silent='cd /sys/devices/platform/asus-nb-wmi; sudo sh -c "echo 2 >> throttle_thermal_policy"; source ~/.zshrc; cd ~;'
alias gpu-intel='sudo prime-select intel; echo "Now restart your cazan, you bastard! Be aware external monitor will not work!!!!!"'
alias gpu-nvidia='sudo prime-select on-demand; echo "Now restart your cazan, you bastard!"'


alias pimaster='ssh silviun@pimaster'
alias pigreen='ssh silviun@hass.green.silviun.net'
alias pimasterremote='ssh silviun@silviun-home.go.ro'

alias mysql-tunnel-sesam-dev='ssh mysql_tunnel@10.55.26.250 -L 33060:10.55.26.21:30108 -N'
alias mysql-tunnel-sesam-rct='ssh mysql_tunnel@10.55.5.250 -L 33061:10.55.5.21:30108 -N'
alias mysql-tunnel-sesam-rct2='ssh mysql_tunnel@10.55.16.250 -L 33062:10.55.16.21:30108 -N'
alias mysql-tunnel-sesam-live='ssh mysql_tunnel@10.55.6.250 -L 33063:10.55.6.21:30108 -N'

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

#vpn
alias dc01='nmcli con up id dc01 --ask || nmcli con down id dc01'

vpnup() {
  local token_var password_file
  print "Please insert token value below"
  read -rs token_var
  print

  password_file="$(mktemp "${TMPDIR:-/tmp}/vpn-pass.XXXXXX")" || return 1
  chmod 600 "$password_file"
  trap 'rm -f "$password_file"' EXIT INT TERM
  print -r -- "vpn.secrets.password:${LDAP_PASS:-}${token_var}" > "$password_file"
  nmcli con up id dc01 passwd-file "$password_file"
  local status=$?
  rm -f "$password_file"
  trap - EXIT INT TERM
  return "$status"
}

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

ointellij() {
  local project_relative_path project_absolute_path
  project_relative_path="$(find "$PROJECTS_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | fzf)" ||
    return 1
  [[ -n "$project_relative_path" ]] || return 1
  project_absolute_path="$PROJECTS_PATH/$project_relative_path"

  if command -v idea >/dev/null 2>&1; then
    idea "$project_absolute_path" >/dev/null 2>&1 &
  elif [[ -x "$IDEA_PATH/idea.sh" ]]; then
    "$IDEA_PATH/idea.sh" "$project_absolute_path" >/dev/null 2>&1 &
  elif [[ "$OSTYPE" == darwin* ]]; then
    command open -a "IntelliJ IDEA" "$project_absolute_path"
  else
    print -u2 "IntelliJ IDEA launcher not found; set IDEA_PATH in ~/.zshrc.local."
    return 1
  fi
}

gitcheckout() {
  local project_relative_path project_absolute_path branch_name local_branch
  project_relative_path="$(find "$PROJECTS_PATH" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | fzf)" ||
    return 1
  [[ -n "$project_relative_path" ]] || return 1
  project_absolute_path="$PROJECTS_PATH/$project_relative_path"
  branch_name="$(getallbranches "$project_absolute_path")" || return 1
  [[ -n "$branch_name" ]] || return 1
  local_branch="${branch_name#origin/}"

  if git -C "$project_absolute_path" show-ref --verify --quiet "refs/heads/$local_branch"; then
    git -C "$project_absolute_path" switch "$local_branch"
  else
    git -C "$project_absolute_path" switch --create "$local_branch" --track "$branch_name"
  fi
  print "Checked out $local_branch in $project_absolute_path"
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


pullsecrets() {
  python3 "$PROJECTS_PATH/automation/scripts/gitlab_secrets/secrets_mgmt.py" -p
}

updatesecrets() {
  python3 "$PROJECTS_PATH/automation/scripts/gitlab_secrets/secrets_mgmt.py" -u "$1"
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

alias ytunnel-awsprod='ssh -L 8443:FFDFCF7D2956B10DF7ACC36F3B97BC9C.gr7.eu-west-1.eks.amazonaws.com:443 silneg@10.4.185.97 -N'
alias yssh-awsprod='ssh silneg@10.4.185.97'

alias yssh-m1='ssh silneg@10.241.0.5'
alias ytunnel-m1='ssh -L 7443:eid-southeastasia-prod-dns-60e52707.4f8a35aa-c4bc-4dfe-885c-9e0ac2e281d5.privatelink.southeastasia.azmk8s.io:443 silneg@10.241.0.5 -N'

alias yssh-santander='ssh silneg@10.34.8.241'
alias ytunnel-santander='ssh -L 9443:D6F2EB52FD37CAF6BE5FF13FA87DF22F.gr7.eu-west-1.eks.amazonaws.com:443 silneg@10.34.8.241 -N'


alias yssh-devstaging='ssh silneg@52.209.4.175'
alias ytunnel-devstaging='ssh -L 6443:E32F4804027CB96FE51242A0E1909AFE.sk1.eu-west-1.eks.amazonaws.com:443 silneg@52.209.4.175 -N'


alias yssh-carrefour='ssh silneg@172.18.64.4'
alias ytunnel-carrefour='ssh -L 8443:eid-carrefour-prod-dns-3800287e.e5274f6c-4f1e-436d-a734-6bfd498c4ce9.privatelink.westeurope.azmk8s.io:443 silneg@172.18.64.4 -N'


alias yssh-sesam-rct='ssh user@10.55.5.250'
alias yssh-sesam-rct2='ssh user@10.55.16.250'
alias yssh-sesam-dev='ssh user@10.55.26.250'
alias yssh-sesam-prod='ssh user@10.55.6.250'

alias yssh-xfr-live='ssh silneg@10.226.2.18'
alias yssh-tec='ssh silneg@10.226.2.18'
