#!/usr/bin/env bash

urlencodepipe() {
  local LANG=C; local c; while IFS= read -r c; do
    case $c in [a-zA-Z0-9.~_-]) printf "$c"; continue ;; esac
    printf "$c" | od -An -tx1 | tr ' ' % | tr -d '\n'
  done <<EOF
$(fold -w1)
EOF
  echo
}


urlencode() { printf "$*" | urlencodepipe ;}


#personal
function open () {
    xdg-open "$*" &>/dev/null
}

function singleton(){
	local running=1
	if [ -z "$@" ] || [ "$#" -gt 2 ]; then
		echo "Usage : singleton [application] [identifier in ps -e]"
	else
		if ([ "$#" -eq 2 ] && [ -z $(pgrep -x "$2") ]) || ([ "$#" -eq 1 ] && [ -z $(pgrep -x "$1") ]); then
			nohup "$1" > /dev/null 2>&1 &
		fi
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
  dir=$(find ${1:-*} -path '*/\.*' -prune \
             -o -type d -print 2> /dev/null | awk '{print length($1), $1}' | sort -n | cut -d ' ' -f 2- | fzf +m) &&
  cd "$dir"
}

# fda - including hidden directories
fda() {
  local dir
  dir=$(find ${1:-.} -type d 2> /dev/null | fzf +m) && cd "$dir"
}

# ffasd - change directory from a list
ffasd() {
    local directories directory
    directories=$(fasd -ldrR | awk '{print length($1), $1}' | sort -n | cut -d ' ' -f 2- ) &&
        directory=$(echo "$directories" | fzf +s +m) &&
        cd $(echo "$directory")
}
bindkey -s '^O' '^qffasd\n'

# fkill - kill process
fkill() {
  ps -ef | sed 1d | fzf -m | awk '{print $2}' | xargs sudo kill -${1:-9}
}

# fbr - checkout git branch
fgb() {
    git pull
    local branches branch
    branches=$(git branch) &&
        branch=$(echo "$branches" | fzf +s +m) &&
        git checkout $(echo "$branch" | sed "s/.* //")
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
  commit=$(echo "$commits" | fzf +s +m -e) &&
  git checkout $(echo "$commit" | sed "s/ .*//")
}

# fzgt - checkout git tags
fgt() {
  local tags tag
  tags=$(git tag) &&
  tag=$(echo "$tags" | fzf +s +m) &&
  git checkout tags/$(echo "$tag" | sed "s/.* //")
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

function cd() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -p | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -p --color=always "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}

ch() {
  local cols sep google_history open
  cols=$(( COLUMNS / 3 ))
  sep='{::}'

  if [ "$(uname)" = "Darwin" ]; then
    google_history="$HOME/Library/Application Support/Google/Chrome/Default/History"
    open=open
  else
    google_history="$HOME/.config/google-chrome/Default/History"
    open=xdg-open
  fi
  cp -f "$google_history" /tmp/h
  sqlite3 -separator $sep /tmp/h \
    "select substr(title, 1, $cols), url
     from urls order by last_visit_time desc" |
  awk -F $sep '{printf "%-'$cols's  \x1b[36m%s\x1b[m\n", $1, $2}' |
  fzf --ansi --multi | sed 's#.*\(https*://\)#\1#' | xargs $open > /dev/null 2> /dev/null
}

#lpass
lastpass() {lpass show -c --password $(lpass ls  | fzf | awk '{print $(NF)}' | sed 's/\]//g')}

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
docker_is_active=`systemctl is-active docker &> /dev/null`
if [ $docker_is_active ]; then
    alias dobuild='docker build .'
    alias dobuildrunlastimage='docker build . && docker run -d `docker images -q|head -1`'
    alias dorestart='sudo systemctl start docker'
    alias doimages='docker images'
    #delete all stopped containers
    alias dormall='docker rm $(docker ps -a -q)'
    alias dostopall='docker stop $(docker ps -q)'
    alias dopsa='docker ps -a'
    alias dops='docker ps'
    alias dormiall='docker rmi `docker images -q`'
    alias donosudo='sudo groupadd docker ; usermod -a -G docker ${USERNAME} ; sudo gpasswd -a ${USERNAME} docker ; sudo service docker restart'
    alias dolastimage='docker images -q|head -1'
    alias dostoplast='docker stop `docker ps -q|head -1`'
    alias doimagesqhead1='docker images -q|head -1'
    alias docontainersqhead1='docker ps -a -q|head -1'
    alias dopsqhead1='docker ps -q|head -1'
    # alias dorunlastimage='docker run -d `docker images -q|head -1`'
    alias doretrylast="dostoplast && dorunlastimage && sleep 1s && dosshlast"
    #delete all untagged images
    alias docleanintermediary="docker rmi $(docker images | grep '^<none>' | awk '{print $3}')"
    #cleanpup. delete all stopped containers and remove untagged images
    alias docleanall="dormall ; dormiall"
;fi

gitreview(){
    if [ -z "$1" ]
    then
        BASE_BRANCH="master"
        BRANCH_TO_REVIEW=`git rev-parse --abbrev-ref HEAD`
    else
        BASE_BRANCH="$1"
        BRANCH_TO_REVIEW="$2"
    fi
    git reset --hard; git clean -f -d
    echo "switching to branch $BASE_BRANCH"
    eval "git checkout $BASE_BRANCH"
    echo "merging $BRANCH_TO_REVIEW into $BASE_BRANCH"
    eval "git merge $BRANCH_TO_REVIEW"
}

# bind keys

getbranchname(){
    if [ -d $1/.git ]
    then
        echo `(cd $1; git branch | grep \* | cut -d ' ' -f2)`
    else
        echo `(cd $1; hg branch)`
    fi
}

getallbranches() {
    echo `(cd $1; git fetch && (git branch -r  | fzf))`
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
    grep '^function ' "$file" | sed 's/^function \([^ ]*\) .*/\1/'

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
    awk '/^function / { name = $2; getline; if ($0 ~ /^#/) { comment = substr($0, 2); } else { comment = ""; } print "- " name " : " comment }' "$file"

    echo "Aliases:"
    awk '/^alias / { name = $2; getline; if ($0 ~ /^#/) { comment = substr($0, 2); } else { comment = ""; } print "- " name " : " comment }' "$file"
}


dothelp() {
  list_functions_aliases_with_comments $HOME'/.my_aliases.sh'
}

get_env_var_value() {
  local namespace=dashboard-1
  local app=$1  # Use the app parameter passed to the function
  # Get dbIp and redisIp using kubectl commands
  dbIp=$(kubectl get configmap -n "$namespace" postgresql-cmek-"$app" -o jsonpath='{.data.DATABASE_HOST}')
  redisIp=$(kubectl get configmap -n "$namespace" redis -o jsonpath='{.data.REDIS_HOST}')

  # Format into YAML
  yaml=$(cat <<EOF

egress:
  dbIp: $dbIp
  redisIp: $redisIp
  dnsHosts:
    - api.signicat.com
EOF
  )

  echo "$yaml"
  echo ""
}

write_to_file() {
  app=$1
  file_path=$2

  # Check if file contains 'egress'
  if ! grep -q 'egress' "$file_path"; then
    # Append the output of the function to the end of the file
    get_env_var_value "$app" >> "$file_path"
    echo "written to $file_path"
  fi
}
function givemedata() {
  local env="dev"
#echo "ncs"
#write_to_file "ncs" /home/silviun/projects/notification-center-service/infra/helm-values/$env.yaml
#
#echo "oapi"
#write_to_file "oapi" /home/silviun/projects/octopus/infra/helm-values/$env.yaml
#
#echo "theming"
#write_to_file "theming" /home/silviun/projects/theming-api/infra/helm-values/$env.yaml
#
#echo "storefront"
#write_to_file "storefront" /home/silviun/projects/storefront/infra/helm-values/$env.yaml
#
#echo "pay-api"
#write_to_file "pay-api" /home/silviun/projects/payment-api/infra/helm-values/$env.yaml

#echo "dashboard-svc"
#write_to_file "dashboard-svc" /home/silviun/projects/dashboard-service/infra/helm-values/$env.yaml
}


gitlab_projects=("storefront" "dashboard-service" "octopus" "notification-center-service" "theming-api" "payment-api" "td1-mfes" "automation" )

transform_string() {
    input_string="$1"

    # Replace "-" with space and capitalize each word
    transformed_string=$(echo "$input_string" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')

    echo "$transformed_string"
}

function show_gitlab_project_info() {

  local app=$1
  # GitLab API URL
  API_URL="https://gitlab.com/api/v4/projects/signicat%2Forange-stack%2Fself-service%2F$app/pipelines"

  # GitLab Private Token
  PRIVATE_TOKEN="$GITLAB_PRIVATE_TOKEN"

  # Fetching pipeline information with authentication
  response=$(curl -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$API_URL")
  # Parsing JSON to get the latest pipeline URL
  latest_pipeline_url=$(echo "$response" | jq -r '.[0].web_url')

  # Output the latest pipeline URL
  echo "Project:             https://gitlab.com/signicat/orange-stack/self-service/$app"
  echo "Latest pipeline URL: $latest_pipeline_url"
  echo "Merge Requests:      https://gitlab.com/signicat/orange-stack/self-service/$app/-/merge_requests"
  echo ""
}
function show_gitlab_latest_pipeline() {

  local app=$1
  # GitLab API URL
  API_URL="https://gitlab.com/api/v4/projects/signicat%2Forange-stack%2Fself-service%2F$app/pipelines"

  # GitLab Private Token
  PRIVATE_TOKEN="$GITLAB_PRIVATE_TOKEN"

  # Fetching pipeline information with authentication
  response=$(curl -s --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" "$API_URL")
  # Parsing JSON to get the latest pipeline URL
  latest_pipeline_url=$(echo "$response" | jq -r '.[0].web_url')

  # Output the latest pipeline URL
  echo "$latest_pipeline_url"
}


oallgitprojectinfos() {
 for project in "${gitlab_projects[@]}"; do
     transformed_project=$(transform_string "$project")
     echo "$transformed_project"
     show_gitlab_project_info $project
 done
}
oallgitprojectlatestpipelines() {
 for project in "${gitlab_projects[@]}"; do
     transformed_project=$(transform_string "$project")
     latest_pipeline=$(show_gitlab_latest_pipeline "$project")
     echo "$transformed_project - $latest_pipeline"
 done
}

function ogitprojectinfo() {
  selected_project=$(printf "%s\n" "${gitlab_projects[@]}" | fzf --prompt="Select a project: ")
  transformed_project=$(transform_string "$selected_project")
  echo $transformed_project
  show_gitlab_project_info $selected_project
}

function createfile() {
  # Check if the user provided the filename and size as arguments
  if [ $# -ne 2 ]; then
      echo "Usage: $0 <filename> <size>"
      exit 1
  fi

  # Extract arguments
  filename=$1
  size=$2

  # Use dd to create the file with the specified size
  dd if=/dev/zero of="$filename" bs=1 count="$size" 2>/dev/null

  # Check if the file was created successfully
  if [ $? -eq 0 ]; then
      echo "File $filename created successfully with size $size bytes."
  else
      echo "Failed to create file $filename."
  fi
}

