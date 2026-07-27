#!/usr/bin/env zsh

alias mvnc='mvn clean install -DskipTests -DskipITs -T03.C'
alias mvni='mvn install -DskipTests -DskipITs -T03.C'

mvnd() {
  mvn dependency:tree | "${PAGER:-less}"
}

mvn-settings() {
  local profile="${1:-}" source
  case "$profile" in
    y|yellow)
      source="$HOME/.m2/settings.y.xml"
      ;;
    d|dev|default)
      source="$HOME/.m2/settings.d.xml"
      ;;
    *)
      print -u2 "Usage: mvn-settings <y|d>"
      return 2
      ;;
  esac

  if [[ ! -r "$source" ]]; then
    print -u2 "Maven settings file is not readable: $source"
    return 1
  fi

  command cp -- "$source" "$HOME/.m2/settings.xml" &&
    print "Using Maven settings from $source"
}

alias mvnsy='mvn-settings y'
alias mvnsd='mvn-settings d'

alias homelab-pi='ssh silviun@homelab-pi'
alias homelab-green='ssh silviun@hass.green.silviun.net'
alias homelab-main='ssh silviun@homelab-main'

_pitemp_read_temperature() {
  if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd measure_temp
  elif [[ -r /sys/class/thermal/thermal_zone0/temp ]]; then
    awk '{printf "temp=%.1f°C\n", $1 / 1000}' \
      /sys/class/thermal/thermal_zone0/temp
  else
    print -u2 "No Raspberry Pi temperature source found."
    return 1
  fi
}

_pitemp_local_loop() {
  local interval="$1"
  while true; do
    printf '%s  ' "$(date '+%Y-%m-%d %H:%M:%S')"
    _pitemp_read_temperature || return 1
    sleep "$interval" || return 1
  done
}

pitemp() {
  local host="${PI_TEMP_HOST:-silviun@homelab-pi}" interval=1 mode=remote
  local explicit_host=0

  if (( $# > 2 )); then
    print -u2 "Usage: pitemp [local|ssh-host] [interval-seconds]"
    return 2
  fi

  if (( $# == 1 )); then
    if [[ "$1" == "local" ]]; then
      mode=local
    elif [[ "$1" == <-> ]]; then
      interval="$1"
    else
      host="$1"
      explicit_host=1
    fi
  elif (( $# == 2 )); then
    if [[ "$1" == "local" ]]; then
      mode=local
    else
      host="$1"
      explicit_host=1
    fi
    interval="$2"
  fi

  if [[ "$interval" != <-> ]] || (( interval < 1 || interval > 3600 )); then
    print -u2 "Interval must be an integer between 1 and 3600 seconds."
    return 2
  fi

  if [[ "$mode" == "local" ]] ||
     (( ! explicit_host )) &&
       { command -v vcgencmd >/dev/null 2>&1 ||
         [[ -r /sys/class/thermal/thermal_zone0/temp ]]; }; then
    print "Monitoring local Raspberry Pi temperature every ${interval}s; Ctrl-C to stop."
    _pitemp_local_loop "$interval"
    return
  fi

  print "Monitoring $host every ${interval}s; Ctrl-C to stop."
  ssh "$host" "PI_TEMP_INTERVAL=$interval sh -s" <<'REMOTE'
while :; do
  printf '%s  ' "$(date '+%Y-%m-%d %H:%M:%S')"
  if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd measure_temp
  elif [ -r /sys/class/thermal/thermal_zone0/temp ]; then
    awk '{printf "temp=%.1f°C\n", $1 / 1000}' \
      /sys/class/thermal/thermal_zone0/temp
  else
    printf '%s\n' "No Raspberry Pi temperature source found." >&2
    exit 1
  fi
  sleep "$PI_TEMP_INTERVAL" || exit 1
done
REMOTE
}

use-java() {
  local version="${1:-}" previous_java_home="${JAVA_HOME:-}" selected_java_home
  if [[ -z "$version" ]]; then
    print -u2 "Usage: use-java <version>"
    return 2
  fi
  if [[ ! -x /usr/libexec/java_home ]]; then
    print -u2 "use-java is available only on macOS with /usr/libexec/java_home."
    return 1
  fi

  selected_java_home="$(/usr/libexec/java_home -v "$version")" || return 1
  if [[ -n "$previous_java_home" ]]; then
    path=("${(@)path:#${previous_java_home}/bin}")
  fi
  export JAVA_HOME="$selected_java_home"
  typeset -U path PATH
  path=("$JAVA_HOME/bin" $path)
  rehash
  print "JAVA_HOME=$JAVA_HOME"
}

alias java21='use-java 21'
alias java25='use-java 25'

alias yvpn='netbird service start && netbird up'

ogitflux() {
  open_url "https://gitlab.com/signicat/orange-stack/self-service"
}

_dotfiles_select_repository() {
  local requested="${1:-}" selected
  if [[ -n "$requested" ]]; then
    if [[ -d "$requested" ]]; then
      print -r -- "${requested:A}"
    elif [[ -d "$PROJECTS_PATH/$requested" ]]; then
      print -r -- "${PROJECTS_PATH:A}/$requested"
    else
      print -u2 "Repository directory not found: $requested"
      return 1
    fi
    return
  fi

  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    git rev-parse --show-toplevel
    return
  fi

  selected="$(
    find "$PROJECTS_PATH" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null |
      sort |
      fzf
  )" || return 1
  [[ -n "$selected" ]] && print -r -- "$selected"
}

_dotfiles_git_web_url() {
  local repository="$1" remote host remote_path remainder
  remote="$(git -C "$repository" remote get-url origin)" || return 1
  remote="${remote%.git}"

  case "$remote" in
    git@*:* )
      remainder="${remote#git@}"
      host="${remainder%%:*}"
      remote_path="${remainder#*:}"
      print -r -- "https://$host/$remote_path"
      ;;
    ssh://git@*/* )
      remainder="${remote#ssh://git@}"
      host="${remainder%%/*}"
      remote_path="${remainder#*/}"
      print -r -- "https://$host/$remote_path"
      ;;
    http://*|https://* )
      print -r -- "$remote"
      ;;
    * )
      print -u2 "Unsupported Git remote URL: $remote"
      return 1
      ;;
  esac
}

gitlab-open() {
  local action="${1:-repo}" requested="${2:-}" repository branch web_url
  if ! command -v glab >/dev/null 2>&1; then
    print -u2 "glab is required for gitlab-open."
    return 1
  fi

  repository="$(_dotfiles_select_repository "$requested")" || return 1
  if ! git -C "$repository" rev-parse --git-dir >/dev/null 2>&1; then
    print -u2 "Not a Git repository: $repository"
    return 1
  fi

  case "$action" in
    repo)
      (builtin cd -- "$repository" && glab repo view --web)
      ;;
    branch)
      branch="$(git -C "$repository" branch --show-current)" || return 1
      if [[ -z "$branch" ]]; then
        print -u2 "The repository is in detached HEAD state."
        return 1
      fi
      (builtin cd -- "$repository" && glab repo view --web --branch "$branch")
      ;;
    mrs|merge-requests)
      web_url="$(_dotfiles_git_web_url "$repository")" || return 1
      open_url "$web_url/-/merge_requests"
      ;;
    pipelines)
      web_url="$(_dotfiles_git_web_url "$repository")" || return 1
      open_url "$web_url/-/pipelines"
      ;;
    *)
      print -u2 "Usage: gitlab-open [repo|branch|mrs|pipelines] [repository]"
      return 2
      ;;
  esac
}

ssh-access-permissions-checker() {
  if [[ -z "${FLUX_AUTOMATION_DIR:-}" ]]; then
    print -u2 "FLUX_AUTOMATION_DIR is not set."
    return 1
  fi

  local checker="$FLUX_AUTOMATION_DIR/local-dev/yellow/environment-access/ssh-access-permissions-checker.sh"
  if [[ ! -x "$checker" ]]; then
    print -u2 "Checker is not executable: $checker"
    return 1
  fi
  "$checker"
}
