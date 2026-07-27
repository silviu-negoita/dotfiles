#!/usr/bin/env zsh

urlencodepipe() {
  local input
  input="$(<&0)"
  urlencode "$input"
}

urlencode() {
  local LC_ALL=C input="$*" output="" character hex index

  for (( index = 1; index <= ${#input}; index++ )); do
    character="${input[index]}"
    case "$character" in
      [a-zA-Z0-9.~_-])
        output+="$character"
        ;;
      *)
        printf -v hex "%02X" "'$character"
        output+="%$hex"
        ;;
    esac
  done

  print -r -- "$output"
}

#personal
open() {
  if [[ "$OSTYPE" == darwin* ]]; then
    command open "$@"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$@" >/dev/null 2>&1 &
  elif command -v gio >/dev/null 2>&1; then
    gio open "$@" >/dev/null 2>&1 &
  else
    print -u2 "No opener found (open, xdg-open, or gio)."
    return 1
  fi
}

singleton() {
  if (( $# < 1 || $# > 2 )); then
    print -u2 "Usage: singleton <application> [process-name]"
    return 2
  fi

  local application="$1" process_name="${2:-$1}"
  if ! pgrep -x -- "$process_name" >/dev/null 2>&1; then
    nohup "$application" >/dev/null 2>&1 &
  fi
}

#Fuzzyfinder
frmf() {
  local file
  file=$(fzf --query="$1" --select-1 --exit-0)
  [ -n "$file" ] && rm -rf "$file"
}

# Equivalent to above, but opens it with `open` command
fop() {
  local file
  file=$(fzf --query="$1" --select-1 --exit-0)
  [ -n "$file" ] && open "$file"
}

# fd - cd to selected directory
fcd() {
  local dir
  dir=$(find "${1:-.}" -path '*/\.*' -prune \
             -o -type d -print 2> /dev/null | fzf +m) &&
  cd "$dir"
}

# fda - including hidden directories
fda() {
  local dir
  dir=$(find "${1:-.}" -type d 2> /dev/null | fzf +m) && cd "$dir"
}

# ffasd - change directory from a list
ffasd() {
  local directories directory
  directories=$(fasd -ldrR | awk '{print length($1), $1}' | sort -n | cut -d ' ' -f 2-) &&
    directory=$(print -r -- "$directories" | fzf +s +m) &&
    cd "$directory"
}
bindkey -s '^O' '^qffasd\n'

# fkill - kill process
fkill() {
  local -a pids
  pids=("${(@f)$(ps -ef | sed 1d | fzf -m | awk '{print $2}')}")
  (( ${#pids} )) && sudo kill "-${1:-9}" -- "${pids[@]}"
}

# fbr - checkout git branch
fgb() {
  git pull --ff-only || return
  local branches branch
  branches=$(git branch) &&
    branch=$(print -r -- "$branches" | fzf +s +m) &&
    git switch "$(print -r -- "$branch" | sed "s/.* //")"
}
bindkey -s '^G' '^qfgb\n'

# fbr - checkout mercurial branch force refresh
fhb() {
    hg pull
    local branches branch
    branches=$(hg branches --closed | sed "s/\s.*//") &&
        branch=$(echo "$branches" | fzf +s +m) &&
        hg purge; hg update $(echo "$branch") -C
}
bindkey -s '^[^H' '^qfhb\n'
# fbr - checkout local mercurial branch
fhbb() {
  local branches branch
  branches=$(hg branches --closed | sed "s/\s.*//") &&
  branch=$(echo "$branches" | fzf +s +m) &&
  hg purge; hg update $(echo "$branch") -C
}
bindkey -s '^H' '^qfhbb\n'

# fco - checkout git commit
fgc() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
  commit=$(print -r -- "$commits" | fzf +s +m -e) &&
  git switch --detach "$(print -r -- "$commit" | sed "s/ .*//")"
}

# fzgt - checkout git tags
fgt() {
  local tags tag
  tags=$(git tag) &&
  tag=$(print -r -- "$tags" | fzf +s +m) &&
  git switch --detach "tags/$(print -r -- "$tag" | sed "s/.* //")"
}

# ftags - search ctags
ftags() {
  local line
  [ -e tags ] &&
  line=$(
    awk 'BEGIN { FS="\t" } !/^!/ {print toupper($4)"\t"$1"\t"$2"\t"$3}' tags |
    cut -c1-80 | fzf --nth=1,2
  ) && $EDITOR $(cut -f3 <<< "$line") -c "set nocst" \
                                      -c "silent tag $(cut -f2 <<< "$line")"
}

cd() {
  if (( $# != 0 )); then
    builtin cd "$@"
    return
  fi

  while true; do
    local directory
    directory="$(
      {
        print ".."
        find . -mindepth 1 -maxdepth 1 -type d -print |
          sed 's#^\./##' |
          sort
      } | fzf --reverse --preview 'ls -p --color=always -- {} 2>/dev/null'
    )"
    [[ -n "$directory" ]] || return 0
    builtin cd "$directory" >/dev/null 2>&1
  done
}

ch() {
  local cols sep google_history opener history_copy
  cols=$(( COLUMNS / 3 ))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    opener=open
  else
    google_history="$HOME/.config/google-chrome/Default/History"
    opener=xdg-open
  fi

  history_copy="$(mktemp "${TMPDIR:-/tmp}/chrome-history.XXXXXX")" || return 1
  if ! cp -f "$google_history" "$history_copy"; then
    rm -f "$history_copy"
    return 1
  fi
  sqlite3 -separator "$sep" "$history_copy" \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F "$sep" '{printf "%-'"$cols"'s  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' |
  while IFS= read -r url; do
    "$opener" "$url" >/dev/null 2>&1
  done
  local status=$?
  rm -f "$history_copy"
  return "$status"
}

#lpass
lastpass() {
  local entry
  entry="$(lpass ls | fzf | awk '{print $(NF)}' | sed 's/\]//g')" || return 1
  [[ -n "$entry" ]] && lpass show -c --password "$entry"
}

# Select a docker container to start and attach to
function da() {
  local cid
  cid=$(docker ps -a | sed 1d | fzf -1 -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker start "$cid" && docker attach "$cid"
}
# Select a running docker container to stop
function ds() {
  local cid
  cid=$(docker ps | sed 1d | fzf -q "$1" | awk '{print $1}')

  [ -n "$cid" ] && docker stop "$cid"
}

# Docker
if command -v docker >/dev/null 2>&1; then
    alias dobuild='docker build .'
    alias dobuildrunlastimage='docker build . && docker run -d "$(docker images -q | head -1)"'
    alias dorestart='sudo systemctl start docker'
    alias doimages='docker images'
    #delete all stopped containers
    alias dormall='docker rm $(docker ps -a -q)'
    alias dostopall='docker stop $(docker ps -q)'
    alias dopsa='docker ps -a'
    alias dops='docker ps'
    alias dormiall='docker rmi $(docker images -q)'
    alias donosudo='sudo groupadd docker; sudo usermod -a -G docker "$USER"; sudo service docker restart'
    alias dolastimage='docker images -q | head -1'
    alias dostoplast='docker stop "$(docker ps -q | head -1)"'
    alias doimagesqhead1='docker images -q | head -1'
    alias docontainersqhead1='docker ps -a -q | head -1'
    alias dopsqhead1='docker ps -q | head -1'
    #delete all untagged images
    alias docleanintermediary='docker rmi $(docker images | awk '"'"'$1 == "<none>" {print $3}'"'"')'
    #cleanpup. delete all stopped containers and remove untagged images
    alias docleanall='dormall; dormiall'
fi

gitreview(){
  local base_branch branch_to_review confirmation
  if (( $# == 0 )); then
    base_branch="$(
      git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null |
        sed 's#^origin/##'
    )"
    if [[ -z "$base_branch" ]]; then
      if git show-ref --verify --quiet refs/heads/main; then
        base_branch=main
      else
        base_branch=master
      fi
    fi
    branch_to_review="$(git branch --show-current)"
  elif (( $# == 2 )); then
    base_branch="$1"
    branch_to_review="$2"
  else
    print -u2 "Usage: gitreview [base-branch branch-to-review]"
    return 2
  fi

  print -u2 "This discards uncommitted and untracked changes in $(pwd)."
  read -r "confirmation?Continue? [y/N] "
  [[ "$confirmation" == [yY] ]] || return 1

  git reset --hard &&
    git clean -fd &&
    git switch "$base_branch" &&
    git merge -- "$branch_to_review"
}

# bind keys

getbranchname(){
  local repository="$1"
  if git -C "$repository" rev-parse --git-dir >/dev/null 2>&1; then
    git -C "$repository" branch --show-current
  else
    hg --cwd "$repository" branch
  fi
}

getallbranches() {
  local repository="$1"
  git -C "$repository" fetch --prune || return 1
  git -C "$repository" branch --remotes --format='%(refname:short)' |
    grep -vE '(^|/)HEAD$' |
    fzf
}

insert_sudo () { zle beginning-of-line; zle -U "sudo " }
zle -N insert-sudo insert_sudo
bindkey "^[s" insert-sudo

list_functions_aliases() {
    local file="$1"
    if [ -z "$file" ]; then
        echo "Usage: list_functions_aliases <shell_file>"
        return 1
    fi

    if [ ! -f "$file" ]; then
        echo "Error: File '$file' does not exist."
        return 1
    fi

    echo "Functions:"
    sed -nE \
      -e 's/^function[[:space:]]+([[:alnum:]_-]+).*/\1/p' \
      -e 's/^([[:alnum:]_-]+)\(\)[[:space:]]*\{.*/\1/p' \
      "$file"

    echo "Aliases:"
    grep '^alias ' "$file" | sed 's/^alias \([^=]*\)=.*/\1/'
}

list_functions_aliases_with_comments() {
    local file="$1"
    if [ -z "$file" ]; then
        echo "Usage: list_functions_aliases_with_comments <shell_file>"
        return 1
    fi

    if [ ! -f "$file" ]; then
        echo "Error: File '$file' does not exist."
        return 1
    fi

    echo "Functions:"
    awk '
      /^[[:space:]]*#/ {
        comment = $0
        sub(/^[[:space:]]*#[[:space:]]*/, "", comment)
        next
      }
      /^function[[:space:]]+/ || /^[[:alnum:]_-]+\(\)[[:space:]]*\{/ {
        name = $0
        sub(/^function[[:space:]]+/, "", name)
        sub(/\(.*/, "", name)
        sub(/[[:space:]].*/, "", name)
        print "- " name (comment == "" ? "" : " : " comment)
        comment = ""
        next
      }
      NF { comment = "" }
    ' "$file"

    echo "Aliases:"
    awk '
      /^[[:space:]]*#/ {
        comment = $0
        sub(/^[[:space:]]*#[[:space:]]*/, "", comment)
        next
      }
      /^alias[[:space:]]+/ {
        name = $0
        sub(/^alias[[:space:]]+/, "", name)
        sub(/=.*/, "", name)
        print "- " name (comment == "" ? "" : " : " comment)
        comment = ""
        next
      }
      NF { comment = "" }
    ' "$file"
}


dothelp() {
  list_functions_aliases_with_comments "$HOME/.my_aliases.sh"
}

get_env_var_value() {
  local namespace=dashboard-1
  local app="$1" db_ip redis_ip yaml
  # Get dbIp and redisIp using kubectl commands
  db_ip=$(kubectl get configmap -n "$namespace" postgresql-cmek-"$app" -o jsonpath='{.data.DATABASE_HOST}')
  redis_ip=$(kubectl get configmap -n "$namespace" redis -o jsonpath='{.data.REDIS_HOST}')

  # Format into YAML
  yaml=$(cat <<EOF

egress:
  dbIp: $db_ip
  redisIp: $redis_ip
  dnsHosts:
    - api.signicat.com
EOF
  )

  echo "$yaml"
  echo ""
}

write_to_file() {
  local app="$1" file_path="$2"

  # Check if file contains 'egress'
  if ! grep -q 'egress' "$file_path"; then
    # Append the output of the function to the end of the file
    get_env_var_value "$app" >> "$file_path"
    echo "written to $file_path"
  fi
}

# Retained for compatibility; the old implementation had no active targets.
givemedata() {
  :
}

gitlab_projects=("storefront" "dashboard-service" "octopus" "notification-center-service" "theming-api" "payment-api" "td1-mfes" "automation" )

transform_string() {
    local input_string="$1" transformed_string

    # Replace "-" with space and capitalize each word
    transformed_string=$(echo "$input_string" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')

    echo "$transformed_string"
}

show_gitlab_project_info() {
  local app="$1" api_url response latest_pipeline_url
  api_url="https://gitlab.com/api/v4/projects/signicat%2Forange-stack%2Fself-service%2F$app/pipelines"

  if [[ -z "${GITLAB_PRIVATE_TOKEN:-}" ]]; then
    print -u2 "GITLAB_PRIVATE_TOKEN is not available."
    return 1
  fi

  response="$(
    curl --fail --silent --show-error \
      --header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
      "$api_url"
  )" || return 1
  latest_pipeline_url="$(print -r -- "$response" | jq -r '.[0].web_url // "none"')"

  # Output the latest pipeline URL
  echo "Project:             https://gitlab.com/signicat/orange-stack/self-service/$app"
  echo "Latest pipeline URL: $latest_pipeline_url"
  echo "Merge Requests:      https://gitlab.com/signicat/orange-stack/self-service/$app/-/merge_requests"
  echo ""
}


oallgitprojectinfos() {
  local project transformed_project
  for project in "${gitlab_projects[@]}"; do
    transformed_project="$(transform_string "$project")"
    print "$transformed_project"
    show_gitlab_project_info "$project"
  done
}

ogitprojectinfo() {
  local selected_project transformed_project
  selected_project="$(printf "%s\n" "${gitlab_projects[@]}" | fzf --prompt="Select a project: ")" ||
    return 1
  [[ -n "$selected_project" ]] || return 1
  transformed_project="$(transform_string "$selected_project")"
  print "$transformed_project"
  show_gitlab_project_info "$selected_project"
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
