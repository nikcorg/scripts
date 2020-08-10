__DB_COMP=()

_find_all_databases() {
  while read -r; do
    __DB_COMP+=("$REPLY")
  done < <(psql -l -A | tail -n+3 | grep -v '^(' | cut -d '|' -f 1 | sort | uniq)
}

_find_database() {
  local cur prev

  if (( ${#__DB_COMP[@]} == 0 )); then
    _find_all_databases
  fi

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  COMPREPLY=()

  if [[ "$prev" == "psql" ]] || [[ "$prev" == "pgcli" ]] || [[ "$prev" == "dropdb" ]]; then
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W "${__DB_COMP[@]}" -- "${cur}") )
  elif [ "$prev" = "-f" ]; then
    # shellcheck disable=SC2207
    COMPREPLY=( $(compgen -W ./*.sql -- "${cur}") )
  fi

  return 0
}

complete -o default -F _find_database pgcli
complete -o default -F _find_database dropdb
complete -o default -F _find_database psql
