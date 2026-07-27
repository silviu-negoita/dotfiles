# Compatibility stub for older ~/.zshrc files that still list `rbates`.
# The maintained commands now live in zsh/*.zsh.
if (( $+functions[c] && $+functions[_c] && $+functions[compdef] )); then
  compdef _c c
fi
