m() {
  local phome=$HOME/src/musicglue
  local dest=""

  if [ "x$1" = "x" ]; then
    cd $phome/platform
    return 0
  fi

  # find a match in projects omitting themes
  if [ ! -d "$dest" ]; then
    dest=$(find $phome -maxdepth 1 -mindepth 1 -type d -name "$1" ! -name 'themes' ! -name 'io-*' -print -quit)
  fi

  # find a match in themes
  if [ ! -d "$dest" ]; then
    dest=$(find $phome/themes -maxdepth 1 -mindepth 1 -type d -name "$1" -print -quit)
  fi

  # find a match in yggdrasil
  if [ ! -d "$dest" ]; then
    dest=$(find $phome/yggdrasil/apps -maxdepth 1 -mindepth 1 -type d -name "$1" -print -quit)
  fi

  # find a partial match in projects
  if [ ! -d "$dest" ]; then
    dest=$(find $phome -maxdepth 1 -mindepth 1 -type d -name "*$1*" ! -name 'themes' ! -name 'io-*' -print -quit)
  fi

  # find a partial match in themes
  if [ ! -d "$dest" ]; then
    dest=$(find $phome/themes -maxdepth 1 -mindepth 1 -type d -name "*$1*" -print -quit)
  fi

  # find a match in yggdrasil
  if [ ! -d "$dest" ]; then
    dest=$(find $phome/yggdrasil/apps -maxdepth 1 -mindepth 1 -type d -name "*$1*" -print -quit)
  fi

  # still no match? well, shucks...
  if [ ! -d "$dest" ]; then
    echo "Unrecognised: $1"
    return 1
  fi

  cd "$dest" || return 1

  return 0
}

__M_ALL_PROJECTS=()

_mg_find_all_repos() {
  while IFS=$'\0' read -r -d $'\0'; do
    __M_ALL_PROJECTS+=("$(basename "$REPLY")")
  done < <(find ~/src/musicglue -type d -maxdepth 1 -mindepth 1 ! -name 'themes' -print0)

  while IFS=$'\0' read -r -d $'\0'; do
    __M_ALL_PROJECTS+=("$(basename "$REPLY")")
  done < <(find ~/src/musicglue/themes -type d -maxdepth 1 -mindepth 1 -print0)

  while IFS=$'\0' read -r -d $'\0'; do
    __M_ALL_PROJECTS+=("$(basename "$REPLY")")
  done < <(find ~/src/musicglue/yggdrasil/apps -type d -maxdepth 1 -mindepth 1 -print0)
}

_mg_find_repo() {
  local cur

  if (( ${#__M_ALL_PROJECTS[@]} == 0 )); then
    _mg_find_all_repos
  fi

  cur="${COMP_WORDS[COMP_CWORD]}"

  COMPREPLY=( $(compgen -W "${__M_ALL_PROJECTS[*]}" -- "${cur}") )

  return 0
}

complete -F _mg_find_repo m
