#!/usr/bin/env zsh

dl() {
  docker logs -f "$1"
}

dr() {
  docker restart "$1"
}

drl() {
  dr "$1" && dl "$1"
}

da() {
  local container
  container="$(
    docker ps -a --format '{{.ID}}\t{{.Names}}\t{{.Status}}' |
      fzf -1 -q "${1:-}" |
      awk '{print $1}'
  )" || return 1
  [[ -n "$container" ]] &&
    docker start "$container" &&
    docker attach "$container"
}

ds() {
  local container
  container="$(
    docker ps --format '{{.ID}}\t{{.Names}}\t{{.Status}}' |
      fzf -1 -q "${1:-}" |
      awk '{print $1}'
  )" || return 1
  [[ -n "$container" ]] && docker stop "$container"
}

# Intentionally retains its historical behavior: stop and remove all containers.
docker-cleanup() {
  local -a containers
  containers=("${(@f)$(docker ps -aq)}")
  if (( ! ${#containers} )); then
    print "No containers to remove."
    return 0
  fi

  print "Stopping..."
  docker stop -- "${containers[@]}" || return 1
  print "Removing..."
  docker rm -- "${containers[@]}"
}

dc() {
  docker-cleanup
}

alias dobuild='docker build .'
alias doimages='docker images'
alias dops='docker ps'
alias dopsa='docker ps -a'
