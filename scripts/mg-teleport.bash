m() {
    local phome=$HOME/src/musicglue
    local dest=$phome/$1

    # find a match in projects omitting themes
    if [ ! -d "$dest" ]; then
        dest=$(find $phome -maxdepth 1 -mindepth 1 -type d ! -name 'themes' -name "*$1*" -print -quit)
    fi

    # find a match in themes
    if [ ! -d "$dest" ]; then
        dest=$(find $phome/themes -maxdepth 1 -mindepth 1 -type d -name "*$1*" -print -quit)
    fi

    if [ ! -d "$dest" ]; then
        echo "Unrecognised: $1"
        return 1
    fi

    cd $dest
    return 0
}

_find_all_repos() {
  find ~/src/musicglue -type d ! -name 'themes' -maxdepth 1 -mindepth 1 -exec basename {} \;
  find ~/src/musicglue/themes -type d -maxdepth 1 -mindepth 1 -exec basename {} \;
}

_find_repo() {
  local cur prev opts
  COMPREPLY=()

  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts=$(_find_all_repos $cur)

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

  return 0
}

complete -o default -F _find_repo m
