_find_all_scripts() {
  if [[ -s "./package.json" ]]; then
   cat package.json | jq -r '.scripts?|keys|.[]'
  fi
}

_find_script() {
  local cur prev opts
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "$prev" == "run" ]]; then
    opts=$(_find_all_scripts)
  fi

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  __ltrim_colon_completions "$cur"

  return 0
}

complete -o default -F _find_script npm
