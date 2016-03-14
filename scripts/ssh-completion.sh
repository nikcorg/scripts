_find_all_ssh_hosts() {
    grep "^Host " ~/.ssh/config | cut -d " " -f 2 | sort | uniq
}

_find_ssh_host() {
    local cur prev opts
    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts=$(_find_all_ssh_hosts)

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )

    return 0
}

complete -o default -F _find_ssh_host ssh
complete -o default -F _find_ssh_host scp
