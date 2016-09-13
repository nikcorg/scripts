_find_all_databases() {
  psql -l -A | tail -n+3 | grep -v '^(' | cut -d '|' -f 1 | sort | uniq
}

_find_database() {
  local cur prev opts
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts=$(_find_all_databases)

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  return 0
}

complete -o default -F _find_database pgcli
