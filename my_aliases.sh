#!/usr/bin/env bash
# constants
export PROJECTS_PATH=$HOME'/projects'
export GITLAB_BASE_URL='https://gitlab.com/signicat/orange-stack/self-service/my-signicat/-/tree/'
export IDEA_PATH=$HOME'/.local/share/JetBrains/Toolbox/apps/IDEA-U/ch-0/212.5457.46/bin/'

#common
alias yankpwd='echo `pwd` | head -c-1 | xclip -sel clip'
reloadshell() {
    echo "Shell is reloaded"
    exec $SHELL -l
}
alias my_aliases='gedit $HOME/.my_aliases.sh &'
alias mvnc='mvn clean install -DskipTests -DskipITs -T03.C'
alias mvni='mvn install -DskipTests -DskipITs -T03.C'
alias mvnd='mvn dependency:tree | gedit -'

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
function gitcleanlocal() {
    git branch -vv | grep 'origin/.*: gone]' | awk '{print $1}' | xargs git branch -D
}
alias gitcleanremote='git remote prune origin'

#vpn
alias dc01='nmcli con up id dc01 --ask || nmcli con down id dc01'

function vpnup() {
  echo "Please insert token value bellow"
  read tokenVar
  echo "vpn.secrets.password:$LDAP_PASS$tokenVar" > /tmp/vpn-pass
  nmcli con up id dc01 passwd-file /tmp/vpn-pass
}
#build
alias fbuild='(cd $FEDERATION_PATH; mvnc)'

#funny
yolo() {
  git commit -m "$(curl http://whatthecommit.com/index.txt)" > /dev/null;
}

#open

alias omessenger='open http://messenger.com'
alias owhatsapp='open https://web.whatsapp.com'

obranch() {
    project_relative_path=`ls ${PROJECTS_PATH} | fzf`
    project_absolute_path=${PROJECTS_PATH}/${project_relative_path}
    branch_name=`getbranchname ${project_absolute_path}`
    gitlab_url=https://gitlab.com/signicat/orange-stack/self-service/${project_relative_path}/-/tree/${branch_name}
    open ${gitlab_url}
}

omergerequests() {
  project_relative_path=`ls ${PROJECTS_PATH} | fzf`

  open https://gitlab.com/signicat/orange-stack/self-service/${project_relative_path}/-/merge_requests
}

#kubectl -n myc get pods
#kubectl -n myc logs -f <pod-name>


ointellij() {
    project_relative_path=`ls ${PROJECTS_PATH} | fzf`
    project_absolute_path=${PROJECTS_PATH}/${project_relative_path}
    ${IDEA_PATH}/idea.sh ${project_absolute_path} > /dev/null
}

gitcheckout() {
    project_relative_path=`ls ${PROJECTS_PATH} | fzf`
    project_absolute_path=${PROJECTS_PATH}/${project_relative_path}
    branch_name=`getallbranches ${project_absolute_path}`

    git checkout -b ${branch_name} --quiet > /dev/null
    echo Checked out ${branch_name}
    #work in progress
}

dl() {
  docker logs -f $1
}

dr() {
  docker restart $1
}

drl() {
  dr $1
  dl $1
}

docker-cleanup() {
  echo "Stopping.. " && docker stop $(docker ps -a -q) && echo "Removing.. " && docker rm $(docker ps -a -q)
}

dc() {
  docker-cleanup
}

dockerrebuild() {
  if [ -z "$1" ];
  then
    echo "Please specify a container"
    return
  fi
    USER="$(id -u)" GROUP="$GROUP_ID" docker-compose \
        -f ./infra/docker-compose/local/docker-compose.external.yml \
        -f ./infra/docker-compose/local/docker-compose.ciam.yml \
        -f ./infra/docker-compose/local/docker-compose.broker.yml \
        -f ./infra/docker-compose/local/docker-compose.internal.yml \
        -f ./infra/docker-compose/local/docker-compose.ema.yml \
        -f ./infra/docker-compose/local/docker-compose.cms.yml \
        -f ./infra/docker-compose/local/docker-compose.fe.yml \
        -f ./infra/docker-compose/local/docker-compose.opa.yml \
        up -d --build --force-recreate --no-deps $1
}

killport() {
 sudo kill -9 `sudo lsof -t -i:$1`
}

#TODO
# install tilix, sublime, fix shortcuts
#

showclip() {
  xclip -selection clipboard -o
}


pullsecrets() {
    python3 ~/projects/automation/scripts/gitlab_secrets/secrets_mgmt.py -p
}

updatesecrets() {
    python3 ~/projects/automation/scripts/gitlab_secrets/secrets_mgmt.py -u $1
}

# wireguard port 51820/ pass gamingpass123