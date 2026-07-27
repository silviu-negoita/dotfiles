#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail

repository_root="${0:A:h:h}"
source "$repository_root/my_aliases.sh"
source "$repository_root/my_functions.sh"

required_commands=(
  yankpwd
  my_aliases
  mvnd
  installfzf
  greet_user
  givemedata
  open
  gitreview
  ogitprojectinfo
  ssh-access-permissions-checker
)

for command_name in "${required_commands[@]}"; do
  whence -w "$command_name" >/dev/null
done

[[ "$(urlencode "a b/c")" == "a%20b%2Fc" ]]
