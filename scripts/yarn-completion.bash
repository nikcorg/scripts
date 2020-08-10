_yarn_commands() {
  cat <<EOT
add
cache
info
link
list
outdated
remove
run
upgrade
upgrade-interactive
EOT
}

_yarn_run_completion_find_all_scripts() {
  if [[ -s "./package.json" ]]; then
    jq -r '.scripts?|keys|.[]' package.json
  fi
}

_yarn_run_completion_find_script() {
  local cmds cur opts prev
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  opts=$(_yarn_run_completion_find_all_scripts)
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "$prev" == "yarn" ]]; then
    cmds=$(_yarn_commands)
    opts=$(echo -e "$opts\n$cmds")
  fi

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  __ltrim_colon_completions "$cur"

  return 0
}

_yarn_upgrade_completion_find_all_deps() {
  if [[ -s "./package.json" ]]; then
    HARD_DEPS=$(jq -r '.dependencies|keys|.[]' package.json)
    DEV_DEPS=$(jq -r '.devDependencies|keys|.[]' package.json)
  fi

  echo -e "$HARD_DEPS\n$DEV_DEPS" | sort
}

_yarn_upgrade_completion_find_dep() {
  local cur opts
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  opts=$(_yarn_upgrade_completion_find_all_deps)

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  __ltrim_colon_completions "$cur"

  return 0
}

_yarn_completion() {
  local prev

  prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "$prev" == "run" || "$prev" == "yarn" ]]; then
    _yarn_run_completion_find_script
  elif [[ "$prev" == "upgrade" ]]; then
    _yarn_upgrade_completion_find_dep
  fi
}

complete -F _yarn_completion yarn

