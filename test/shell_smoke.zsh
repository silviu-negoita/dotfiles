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
[[ "$(_dotfiles_git_web_url "$repository_root")" == "https://github.com/silviu-negoita/dotfiles" ]]

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
  print "temp=42.5'C"
}
[[ "$(_pitemp_read_temperature)" == "temp=42.5'C" ]]
unfunction vcgencmd

typeset pitemp_ssh_call
ssh() {
  pitemp_ssh_call="${(j: :)@}"
  command cat >/dev/null
}
pitemp pi@example.test 3 >/dev/null
[[ "$pitemp_ssh_call" == "pi@example.test PI_TEMP_INTERVAL=3 sh -s" ]]
unfunction ssh

if pitemp local 0 >/dev/null 2>&1; then
  print -u2 "pitemp accepted an invalid interval"
  return 1
fi
