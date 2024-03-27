#!/usr/bin/env bash
# constants
export PROJECTS_PATH=$HOME'/projects'
export GITLAB_BASE_URL='https://gitlab.com/signicat/orange-stack/self-service/my-signicat/-/tree/'
export IDEA_PATH=$HOME'/.local/share/JetBrains/Toolbox/apps/IDEA-U/ch-0/233.14475.28/bin/'


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

# funny
function yoloc() {
  git commit -m "$(curl http://whatthecommit.com/index.txt)" > /dev/null;
}


function yolom() {
  r_message=$(curl -s http://whatthecommit.com/index.txt)
  echo -n "$r_message" | xclip -selection c

  echo "'${r_message}' copied to clipboard: $PUBLIC_IP"
}
#open

alias omessenger='open http://messenger.com'
alias owhatsapp='open https://web.whatsapp.com'
alias ogitflux='open https://gitlab.com/signicat/orange-stack/self-service'

function obranch() {
    project_relative_path=`ls ${PROJECTS_PATH} | fzf`
    project_absolute_path=${PROJECTS_PATH}/${project_relative_path}
    branch_name=`getbranchname ${project_absolute_path}`
    gitlab_url=https://gitlab.com/signicat/orange-stack/self-service/${project_relative_path}/-/tree/${branch_name}
    open ${gitlab_url}
}

function omergerequests() {
  project_relative_path=`ls ${PROJECTS_PATH} | fzf`

  open https://gitlab.com/signicat/orange-stack/self-service/${project_relative_path}/-/merge_requests
}

function ointellij() {
    project_relative_path=`ls ${PROJECTS_PATH} | fzf`
    project_absolute_path=${PROJECTS_PATH}/${project_relative_path}
    ${IDEA_PATH}/idea.sh ${project_absolute_path} > /dev/null
}

function gitcheckout() {
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


killport() {
 sudo kill -9 `sudo lsof -t -i:$1`
}

#TODO
# install tilix, sublime, fix shortcuts
#

# show clipboard
function showclip() {
  xclip -selection clipboard -o
}


pullsecrets() {
    python3 ~/projects/automation/scripts/gitlab_secrets/secrets_mgmt.py -p
}

updatesecrets() {
    python3 ~/projects/automation/scripts/gitlab_secrets/secrets_mgmt.py -u $1
}

ogitpipeline() {
    if [ -z "$GITLAB_URL" ];
    then
      echo "Please specify GITLAB_URL env var"
      return
    fi
    if [ -z "$GITLAB_URL" ];
    then
      echo "Please specify GITLAB_URL env var"
      return
    fi
    if [ -z "$GITLAB_PRIVATE_TOKEN" ];
    then
      echo "Please specify GITLAB_URL env var"
      return
    fi
}

myip() {
  PUBLIC_IP=$(curl -s https://api.ipify.org)

  # Check if xclip is installed
  if ! command -v xclip &> /dev/null; then
      echo "xclip is not installed. Please install it."
      return
  fi

  # Copy public IP address to clipboard
  echo -n "$PUBLIC_IP" | xclip -selection c

  echo "Public IP address copied to clipboard: $PUBLIC_IP"
}

# Function to greet the user
function greet_user {
    echo "Hello, $USER!"
}


