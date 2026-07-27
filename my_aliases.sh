#!/usr/bin/env zsh

# Compatibility loader for existing ~/.zshrc files and external scripts.
typeset _dotfiles_compat_root="${${(%):-%N}:A:h}"
source "$_dotfiles_compat_root/zsh/load.zsh"
unset _dotfiles_compat_root
