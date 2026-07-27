export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
export ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
ZSH_THEME="robbyrussell"

# Keep PATH entries unique and support both Apple Silicon and Intel Homebrew.
typeset -U path PATH
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)
[[ -d /usr/local/bin ]] && path=(/usr/local/bin $path)

# Project-managed aliases and functions.
for config_file in "$HOME"/.my_*(N); do
  [[ -r "$config_file" ]] && source "$config_file"
done
unset config_file

plugins=(
  git
  gem
  rbates
  web-search
  kubectl
  zsh-autosuggestions
  zsh-syntax-highlighting
)

export EDITOR="${EDITOR:-vim}"
export VISUAL="${VISUAL:-$EDITOR}"

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
else
  print -u2 "dotfiles: Oh My Zsh is not installed at $ZSH; run 'rake install'"
fi

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

[[ -r "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# Machine-specific paths and secrets belong here, outside the repository.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
