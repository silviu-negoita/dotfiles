#!/usr/bin/env zsh

# Load the managed shell configuration once, even when compatibility files are
# sourced by an older ~/.zshrc.
[[ -n "${DOTFILES_ZSH_LOADED:-}" ]] && return 0

typeset _dotfiles_zsh_directory="${${(%):-%N}:A:h}"
typeset -g DOTFILES_DIR="${_dotfiles_zsh_directory:h}"

for _dotfiles_module in core git docker work; do
  source "$_dotfiles_zsh_directory/${_dotfiles_module}.zsh" || return 1
done

typeset -g DOTFILES_ZSH_LOADED=1
unset _dotfiles_module _dotfiles_zsh_directory
