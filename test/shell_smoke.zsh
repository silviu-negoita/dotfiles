#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail

repository_root="${0:A:h:h}"

# Both historical entry points must remain safe to source.
source "$repository_root/my_aliases.sh"
source "$repository_root/my_functions.sh"

required_commands=(
  c
  cdf
  yankpwd
  dotedit
  aliashelp
  netspeed
  my_aliases
  mvnd
  mvn-settings
  installfzf
  yoloc
  yolom
  open_url
  fkill
  killport
  gitcleanlocal
  gitcleanremote
  gitlab-open
  docker-cleanup
  dc
  pitemp
  pistatus
  kwhere
  kuse
  ssh-access-permissions-checker
  tagversions
)

for command_name in "${required_commands[@]}"; do
  whence -w "$command_name" >/dev/null
done

removed_commands=(
  ch
  fcd
  fda
  frmf
  ffasd
  fhb
  fhbb
  ftags
  lastpass
  singleton
  urlencode
  urlencodepipe
  gitreview
  getallbranches
  greet_user
  givemedata
  get_env_var_value
  write_to_file
  ogitpipeline
  ogitprojectinfo
  oallgitprojectinfos
  dobuildrunlastimage
  docleanall
  docleanintermediary
  docontainersqhead1
  dolastimage
  donosudo
  dorestart
  dormall
  dormiall
  dopsqhead1
  dostopall
  dostoplast
  homelab-pi
  homelab-green
  homelab-main
)

for command_name in "${removed_commands[@]}"; do
  if whence -w "$command_name" >/dev/null; then
    print -u2 "Removed command is still defined: $command_name"
    return 1
  fi
done

[[ "$DOTFILES_ZSH_LOADED" == 1 ]]
[[ "$(alias mvnsy)" == "mvnsy='mvn-settings y'" ]]
[[ "$(alias gitcleanremote)" == "gitcleanremote='git remote prune origin'" ]]
[[ "$(alias dops)" == "dops='docker ps'" ]]
[[ "$(alias hl-pi)" == "hl-pi='ssh silviun@homelab-pi'" ]]
[[ "$(alias hl-green)" == "hl-green='ssh silviun@hass.green.silviun.net'" ]]
[[ "$(alias hl-main)" == "hl-main='ssh silviun@homelab-main'" ]]
[[ "$(alias speedtest)" == "speedtest=netspeed" ]]
[[ "$(_dotfiles_git_web_url "$repository_root")" == "https://github.com/silviu-negoita/dotfiles" ]]

alias_help="$(aliashelp)"
documented_aliases=(
  mvnc mvni mvnsy mvnsd
  hl-pi hl-green hl-main
  java21 java25 yvpn
  dobuild doimages dops dopsa
  gitcleanremote speedtest
  "git co" "git sw" "git rs" "git st" "git lg"
)
for alias_name in "${documented_aliases[@]}"; do
  [[ "$alias_help" == *"$alias_name"* ]]
done

typeset network_quality_arguments
networkQuality() {
  network_quality_arguments="${(j: :)@}"
}
netspeed -v
[[ "$network_quality_arguments" == "-v" ]]
unfunction networkQuality

typeset -a docker_calls
docker() {
  if [[ "$1" == "ps" && "$2" == "-aq" ]]; then
    print "container-one"
    print "container-two"
  else
    docker_calls+=("${(j: :)@}")
  fi
}
dc >/dev/null
[[ "${docker_calls[1]}" == "stop -- container-one container-two" ]]
[[ "${docker_calls[2]}" == "rm -- container-one container-two" ]]
unfunction docker

typeset -a git_calls
git() {
  if [[ "$1" == "for-each-ref" ]]; then
    print "old-branch [gone]"
  elif [[ "$1" == "branch" ]]; then
    git_calls+=("${(j: :)@}")
  fi
}
if gitcleanlocal <<< "n" >/dev/null; then
  print -u2 "gitcleanlocal ignored a negative confirmation"
  return 1
fi
(( ${#git_calls} == 0 ))
gitcleanlocal <<< "y" >/dev/null
[[ "${git_calls[1]}" == "branch -D -- old-branch" ]]
unfunction git

vcgencmd() {
  if [[ "$1" == "measure_temp" ]]; then
    print "temp=42.5'C"
  else
    print "throttled=0x0"
  fi
}
[[ "$(_pitemp_read_temperature)" == "temp=42.5'C" ]]
pistatus_output="$(_pistatus_snapshot)"
[[ "$pistatus_output" == *"temp=42.5'C"* ]]
[[ "$pistatus_output" == *"OK (throttled=0x0)"* ]]
unfunction vcgencmd

typeset pi_ssh_call
ssh() {
  pi_ssh_call="${(j: :)@}"
  command cat >/dev/null
}
pitemp pi@example.test 3 >/dev/null
[[ "$pi_ssh_call" == "pi@example.test PI_TEMP_INTERVAL=3 sh -s" ]]
pistatus pi@example.test >/dev/null
[[ "$pi_ssh_call" == "pi@example.test sh -s" ]]
unfunction ssh

if pitemp local 0 >/dev/null 2>&1; then
  print -u2 "pitemp accepted an invalid interval"
  return 1
fi

typeset -a kubectl_calls
kubectl() {
  local arguments="${(j: :)@}"
  kubectl_calls+=("$arguments")

  if [[ "$1" == "config" && "$2" == "current-context" ]]; then
    print "dev-context"
  elif [[ "$1" == "config" && "$2" == "get-contexts" ]]; then
    print "dev-context"
    print "prod-context"
  elif [[ "$1" == "config" && "$2" == "view" ]]; then
    if [[ "$arguments" == *".context.namespace"* ]]; then
      print "team-a"
    elif [[ "$arguments" == *".context.cluster"* ]]; then
      print "dev-cluster"
    elif [[ "$arguments" == *".cluster.server"* ]]; then
      print "https://kubernetes.example.test"
    fi
  elif [[ "$1" == "--context" && "$3" == "get" ]]; then
    print "team-a"
    print "team-b"
  elif [[ "$1" == "config" &&
          ( "$2" == "use-context" || "$2" == "set-context" ) ]]; then
    return 0
  else
    print -u2 "Unexpected kubectl call: $arguments"
    return 1
  fi
}

kwhere_output="$(kwhere)"
[[ "$kwhere_output" == *"Context:   dev-context"* ]]
[[ "$kwhere_output" == *"Namespace: team-a"* ]]

kubectl_calls=()
kuse dev-context team-b >/dev/null
kubectl_call_log="${(j:|:)kubectl_calls}"
[[ "$kubectl_call_log" == *"config use-context dev-context"* ]]
[[ "$kubectl_call_log" == *"config set-context --current --namespace=team-b"* ]]

kubectl_calls=()
if kuse prod-context team-a <<< "no" >/dev/null 2>&1; then
  print -u2 "kuse switched to production without explicit confirmation"
  return 1
fi
kubectl_call_log="${(j:|:)kubectl_calls}"
[[ "$kubectl_call_log" != *"config use-context prod-context"* ]]
unfunction kubectl
