ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"

for f in ~/.my_*;
  do
    source ${f};
  done;

plugins=(git bundler brew gem rbates mvn web-search rand-quote themes)

export PATH="/usr/local/bin:$PATH"
export EDITOR='mate -w'

source $ZSH/oh-my-zsh.sh

# for Homebrew installed rbenv
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

#if [ $TILIX_ID ] || [ $VTE_VERSION ]; then
#        source /etc/profile.d/vte.sh
# fi