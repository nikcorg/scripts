__V_ALL_PROJECTS=()

p() {
  local phome="$HOME/src/venndr"
  local dest=""

  if [[ "$1" == "" ]]; then
    cd "$phome/dockerstack" || return 1
    return 0
  fi

  # find a match in projects
  if [[ ! -d "$dest" ]]; then
    dest=$(find "$phome" -maxdepth 1 -mindepth 1 -type d -name "$1" -print -quit)
  fi

  # find a match in yggdrasil
  if [[ ! -d "$dest" ]]; then
    dest=$(find "$phome/yggdrasil/apps" -maxdepth 1 -mindepth 1 -type d -name "$1" -print -quit)
  fi

  # find a partial match in projects
  if [ ! -d "$dest" ]; then
    dest=$(find "$phome" -maxdepth 1 -mindepth 1 -type d -name "$1*" -print -quit)
  fi

  # find a partial match in projects
  if [ ! -d "$dest" ]; then
    dest=$(find "$phome" -maxdepth 1 -mindepth 1 -type d -name "*$1*" -print -quit)
  fi

  # find a partial match in yggdrasil
  if [ ! -d "$dest" ]; then
    dest=$(find "$phome/yggdrasil/lib" -maxdepth 1 -mindepth 1 -type d -name "$1*" -print -quit)
  fi

  # find a partial match in yggdrasil
  if [ ! -d "$dest" ]; then
    dest=$(find "$phome/yggdrasil/lib" -maxdepth 1 -mindepth 1 -type d -name "*$1*" -print -quit)
  fi

  # still no match? well, shucks...
  if [ ! -d "$dest" ]; then
    echo "unrecognised: $1" >&2
    return 1
  fi

  cd "$dest" || return 1
}

_v_find_all_repos() {
  while IFS=$'\0' read -r -d $'\0'; do
    __V_ALL_PROJECTS+=("$(basename "$REPLY")")
  done < <(find ~/src/venndr -type d -maxdepth 1 -mindepth 1 -print0) # -exec basename {} \;

  while IFS=  read -r -d $'\0'; do
    __V_ALL_PROJECTS+=("$(basename "$REPLY")")
  done < <(find ~/src/venndr/yggdrasil/lib -type d -maxdepth 1 -mindepth 1 -print0) # -exec basename {} \;
}

_v_find_repo() {
  local cur

  if (( ${#__V_ALL_PROJECTS[@]} == 0 )); then
    _v_find_all_repos
  fi

  cur="${COMP_WORDS[COMP_CWORD]}"

  # shellcheck disable=SC2207
  COMPREPLY=( $(compgen -W "${__V_ALL_PROJECTS[*]}" -- "${cur}") )

  return 0
}

complete -F _v_find_repo p

