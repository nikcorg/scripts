_find_all_scripts() {
  if [[ -s "./package.json" ]]; then
   cat package.json | jq -r '.scripts?|keys|.[]'
  fi
}

_find_script() {
  COMPREPLY=()

  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"
  local opts

  if [[ "$prev" == "run" ]]; then
    opts=$(_find_all_scripts)
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

_npm_update_completion_find_dep() {
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
init
outdated
publish
run
update
version
EOT
}

_npm_completion_commands() {
  local cmds=$(_npm_commands)
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
}

_npm_completion_version() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "major minor patch" -- ${cur}) )
}

_npm_completion() {
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "$prev" == "npm" ]]; then
    _npm_completion_commands
  elif [[ "$prev" == "update" ]]; then
    _npm_update_completion_find_dep
  elif [[ "$prev" == "run" ]]; then
    _find_script
  elif [[ "$prev" == "version" ]]; then
    _npm_completion_version
  fi
}

complete -F _npm_completion npm
