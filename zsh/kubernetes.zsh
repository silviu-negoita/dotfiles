#!/usr/bin/env zsh

_dotfiles_require_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    print -u2 "kubectl is required."
    return 1
  fi
}

kwhere() {
  _dotfiles_require_kubectl || return 1

  local context namespace cluster server
  context="$(kubectl config current-context 2>/dev/null)" || return 1
  if [[ -z "$context" ]]; then
    print -u2 "No Kubernetes context is currently selected."
    return 1
  fi

  namespace="$(
    kubectl config view --minify \
      --output='jsonpath={.contexts[0].context.namespace}' 2>/dev/null
  )" || namespace=""
  [[ -n "$namespace" && "$namespace" != "<no value>" ]] || namespace=default

  cluster="$(
    kubectl config view --minify \
      --output='jsonpath={.contexts[0].context.cluster}' 2>/dev/null
  )" || cluster=""
  server="$(
    kubectl config view --minify \
      --output='jsonpath={.clusters[0].cluster.server}' 2>/dev/null
  )" || server=""

  printf '%-10s %s\n' "Context:" "$context"
  printf '%-10s %s\n' "Cluster:" "${cluster:-unknown}"
  printf '%-10s %s\n' "Namespace:" "$namespace"
  printf '%-10s %s\n' "Server:" "${server:-unknown}"
}

kuse() {
  _dotfiles_require_kubectl || return 1

  if (( $# > 2 )); then
    print -u2 "Usage: kuse [context] [namespace]"
    return 2
  fi

  local target_context="${1:-}" target_namespace="${2:-}"
  local contexts namespaces confirmation

  contexts="$(kubectl config get-contexts -o name)" || return 1
  if [[ -z "$contexts" ]]; then
    print -u2 "No Kubernetes contexts are configured."
    return 1
  fi

  if [[ -z "$target_context" ]]; then
    if ! command -v fzf >/dev/null 2>&1; then
      print -u2 "fzf is required when no context is provided."
      return 1
    fi
    target_context="$(
      print -r -- "$contexts" | fzf --prompt='Kubernetes context> '
    )" || return 1
  elif ! print -r -- "$contexts" | grep -Fxq -- "$target_context"; then
    print -u2 "Unknown Kubernetes context: $target_context"
    return 1
  fi

  namespaces="$(
    kubectl --context "$target_context" get namespaces \
      --output='jsonpath={range .items[*]}{.metadata.name}{"\n"}{end}'
  )" || return 1

  if [[ -z "$target_namespace" ]]; then
    if ! command -v fzf >/dev/null 2>&1; then
      print -u2 "fzf is required when no namespace is provided."
      return 1
    fi
    target_namespace="$(
      print -r -- "$namespaces" | fzf --prompt='Kubernetes namespace> '
    )" || return 1
  elif ! print -r -- "$namespaces" | grep -Fxq -- "$target_namespace"; then
    print -u2 "Unknown namespace '$target_namespace' in context '$target_context'."
    return 1
  fi

  if [[ "${target_context:l}" == *prod* ]]; then
    print -u2 "Production context selected: $target_context"
    read -r "confirmation?Type 'prod' to continue: "
    [[ "$confirmation" == "prod" ]] || return 1
  fi

  kubectl config use-context "$target_context" || return 1
  kubectl config set-context --current --namespace="$target_namespace" ||
    return 1
  kwhere
}
