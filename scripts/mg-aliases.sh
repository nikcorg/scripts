# shellcheck shell=bash
alias nf-start="honcho start"
alias start-accounts="start-userapp accounts=1"
alias start-enterprise="nf-start -f Procfile.enterprise"
alias start-europa="nf-start -f Procfile.yggdrasil"
alias start-rails-console="bundle exec rails c"
alias start-userapp="nf-start -f Procfile.userapp"

alias prune-node-modules='printf "about to prune node_modules from %d directories in %s\nare you sure?\n" "$(find . -type d -maxdepth 1 -mindepth 1|wc -l)" "$(pwd)"; read; for d in $(find . -type d -maxdepth 1 -mindepth 1); do test -d "$d/node_modules" && printf "\033[34m%s\033[0m: \033[33mpruned\033[0m\n" "$d" && rm -r "$d/node_modules" || printf "\033[34m%s\033[0m: \033[37mnothing to do\033[0m\n" "$d"; done'

function last-commit() {
  git log -n 1 --pretty=oneline | awk '{ printf "%s", $1 }'
}

function copy-last-commit() {
  last-commit | pbcopy
}

function migration() {
  if [ "$1" = "" ]; then
    echo "Filename required"
    return 1
  fi
  knex migrate:make -x js "$@"
}

function __varnishcontainerid() {
  local cid

  cid="$(docker ps | grep varnish | awk '{print $1}')"

  if [[ -z "$cid" ]]; then
    echo "Error: the container id for varnish was not found" >&2
    return 75 # EX_TEMPFAIL
  fi

  echo "$cid"
}

function varnishlog() {
  local cid
  cid=$(__varnishcontainerid) && [[ "$cid" ]] && docker exec -t "$cid" varnishlog
}

function varnishreload() {
  local cid
  cid=$(__varnishcontainerid) && [[ "$cid" ]] && docker exec -t "$cid" varnishreload
}

__MG_LEGACY_PLATFORM_APPS=(
  baskets
  catalogues
  checkout
  content
  directory
  events
  graph
  private
  products
  reservations
  shrinkray
  streams
  themes
  viewers
  viewers-proxy
  warehouse
)

function start-platform() {
  local ARG _WORKON_APPS=()

  while (( $# > 0 )); do
    ARG="$1"

    # shellcheck disable=2076
    if [[ " ${__MG_LEGACY_PLATFORM_APPS[*]} " =~ " ${ARG} " ]]; then
      _WORKON_APPS+=("$ARG")
    else
      echo "Unknown service: $ARG"
      return 1
    fi

    shift
  done

  RELOADABLE_APPS="${_WORKON_APPS[*]}" nf-start -f Procfile.platform
}

__MG_LEGACY_PLATFORM_UTILS=( shrinkray localcdn )

function start-utils() {
  local ARG _WORKON_UTILS=()

  while (( $# > 0 )); do
    ARG=$1

    # shellcheck disable=2076
    if [[ " ${__MG_LEGACY_PLATFORM_UTILS[*]} " =~ " ${ARG} " ]]; then
      _WORKON_UTILS+=("$ARG")
    else
      echo "Unknown util: $ARG"
      return 1
    fi

    shift
  done

  RELOADABLE_APPS="${_WORKON_UTILS[*]}" nf-start -f Procfile.utils
}
