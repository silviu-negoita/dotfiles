#!/usr/bin/env bash
#common
alias yankpwd='echo `pwd` | head -c-1 | xclip -sel clip'
alias execshelll='exec $SHELL -l'
alias my-aliases='gedit $HOME/.my-aliases.sh &'
alias mvnc='mvn clean install -DskipTests -DskipITs -T03.C'

#install
alias installfzf='rm -rf ~/.fzf && git clone https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install'

#git
alias gitadd='git add . --all'
alias gitpush='git push'
alias gitpushgitorious='git push gitorious --all'
alias gitpushgitlab='git push gitlab --all'
alias gitpushgithub='git push github --all'
alias gitstatus='git status'
alias gitresethardgitcleanfd='git reset --hard && git clean -f -d'
alias gitremotev='git remote -v'
alias gitlogallgraphonelindecoratesource='git log --all --graph --oneline --decorate --source'
alias gitinit='git init'
alias gitcheckoutmaster='git checkout master'
alias gitpushall='for remote in `git remote|grep -E lab\|hub\|origin`; do git push $remote --all; git push $remote --tags; done'
alias gitpullall='git pull --all'
alias gitbranch='git branch'
alias gitbrancha='git branch -a'
alias gitdiffcachedpatch='git diff --cached > ~/patch.txt'

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
#    hg ci -m "Merge for review, never push this" -s
#    rm -rf /tmp/patch.txt
#    hg export -a -o /tmp/patch.txt -r tip > /dev/null
#    hg strip `hg id -i`
#    hg import --no-commit /tmp/patch.txt
#    hg add .
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

#vpn
alias dc01='nmcli con up id dc01 --ask || nmcli con down id dc01'

#build
alias fbuild='cd $HOME/projects/federation; mvnc'


