#!/usr/bin/env zsh

gitcleanlocal() {
  local branch_output confirmation
  local -a branches

  branch_output="$(
    git for-each-ref \
      --format='%(refname:short) %(upstream:track)' \
      refs/heads |
      awk '/\[gone\]$/ {print $1}'
  )" || return 1

  if [[ -z "$branch_output" ]]; then
    print "No local branches have a gone upstream."
    return 0
  fi

  branches=("${(@f)branch_output}")
  print "Local branches whose upstream is gone:"
  printf '  %s\n' "${branches[@]}"
  read -r "confirmation?Delete these branches with git branch -D? [y/N] "
  [[ "$confirmation" == [yY] ]] || return 1
  git branch -D -- "${branches[@]}"
}

alias gitcleanremote='git remote prune origin'

fgb() {
  local branch
  branch="$(
    git for-each-ref --format='%(refname:short)' refs/heads | sort | fzf +m
  )" || return 1
  [[ -n "$branch" ]] && git switch -- "$branch"
}

fgc() {
  local commit
  commit="$(
    git log --pretty=oneline --abbrev-commit --reverse | fzf +s +m -e
  )" || return 1
  [[ -n "$commit" ]] &&
    git switch --detach "${commit%% *}"
}

fgt() {
  local tag
  tag="$(git tag --sort=-version:refname | fzf +s +m)" || return 1
  [[ -n "$tag" ]] && git switch --detach "tags/$tag"
}

if [[ -o interactive ]]; then
  bindkey -s '^G' '^qfgb\n'
fi
