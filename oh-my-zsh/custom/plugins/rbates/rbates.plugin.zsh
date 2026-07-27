c() {
  builtin cd -- "${PROJECTS_PATH:-$HOME/projects}/${1:-}"
}
_c() { _files -W "${PROJECTS_PATH:-$HOME/projects}" -/; }
compdef _c c

h() {
  builtin cd -- "$HOME/${1:-}"
}
_h() { _files -W "$HOME" -/; }
compdef _h h

# autocorrect is more annoying than helpful
unsetopt correct_all

# a few aliases I like
alias gs='git status'
alias gd='git diff'
alias tlog='tail -f log/development.log'

# Add the plugin's bin directory once.
typeset -U path PATH
path=("${0:A:h}/bin" $path)
