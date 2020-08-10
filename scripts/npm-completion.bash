_find_script() {
  if [[ ! -f "./package.json" ]]; then
    COMPREPLY=()
    return 0
  fi

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local opts

  if [[ "$prev" == "run" ]]; then
    opts=$(jq -r '.scripts?|keys|.[]' package.json)
  fi

  COMPREPLY=( $(compgen -W "${opts} env" -- ${cur}) )

  __ltrim_colon_completions "$cur"

  return 0
}

_npm_update_completion_find_all_deps() {
  if [[ -s "./package.json" ]]; then
    HARD_DEPS=$(jq -r '.dependencies|keys|.[]' package.json)
    DEV_DEPS=$(jq -r '.devDependencies|keys|.[]' package.json)
  fi

  echo -e "$HARD_DEPS\n$DEV_DEPS" | sort
}

_npm_install_update_completion_find_dep() {
  local cur opts
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  opts=$(_npm_update_completion_find_all_deps)

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  __ltrim_colon_completions "$cur"

  return 0
}

_npm_commands() {
  cat <<EOT
dedupe
init
install
outdated
publish
run
start
update
version
EOT
}

_npm_completion_commands() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "$(_npm_commands)" -- ${cur}) )
}

_npm_completion_version() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "major minor patch" -- ${cur}) )
}

_npm_completion() {
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "$prev" in
  npm) _npm_completion_commands ;;
  install) _npm_install_update_completion_find_dep ;;
  run) _find_script ;;
  version) _npm_completion_version ;;
  *) COMPREPLY=()
  esac
}

complete -o bashdefault -o default -F _npm_completion npm
