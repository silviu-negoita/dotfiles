#!/usr/bin/env bash
# constants
export PROJECTS_PATH=$HOME'/projects'
export FEDERATION_PATH=${PROJECTS_PATH}'/federation'
export JENKINS_BASE_URL='https://jenkins.dev.connectis.org/jenkins/job/software/job/federation-pipeline/job/'
export JIRA_BASE_URL='https://connectis.atlassian.net/browse/'
#common
alias yankpwd='echo `pwd` | head -c-1 | xclip -sel clip'
alias reloadshell='exec $SHELL -l'
alias my-aliases='gedit $HOME/.my_aliases.sh &'
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


#vpn
alias dc01='nmcli con up id dc01 --ask || nmcli con down id dc01'

#build
alias fbuild='cd $HOME/projects/federation; mvnc'

#open

alias omessenger='open http://messenger.com'
alias owhatsapp='open https://web.whatsapp.com'
alias orundeck='open https://infra-dc01-rundeck01.connectis.org/menu/home'
alias orobot='singleton /home/silviu/Desktop/robo3t-1.2.1-linux-x86_64-3e50a65/bin/robo3t'

ojenkins() {
    encoded_branch=`(cd ${FEDERATION_PATH};(urlencode $(hg branch)))`
    open ${JENKINS_BASE_URL}${encoded_branch}
}

ojira() {
    jira_branch_param=`(cd ${FEDERATION_PATH};(hg branch)) | sed 's/feature\///'`
    open ${JIRA_BASE_URL}${jira_branch_param}
}

