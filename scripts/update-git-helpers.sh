#!/bin/bash

# Usage: simply run the script,
# add -q for info message suppression
# add -qq for all output suppression

# If you plan to run this script using cron and you feel unsure of
# your cron environment, uncomment the line below and edit the path
#HOME="<path to your home directory here>"

# A space separated list of scripts to keep updated, for options see:
# https://github.com/git/git/tree/master/contrib/completion
SCRIPTS=(
    git-completion.bash
    git-prompt.sh
)

# Where to place the downloaded scripts
DEST="$HOME/bin"

# Where to download the scripts from
URLSTEM="https://raw.githubusercontent.com/git/git/master/contrib/completion"

# Error exit codes
ERR_DOWNLOAD_FAILED=1
ERR_DEST_DIR_MISSING=2
ERR_HOME_PATH_UNKNOWN=3
ERR_MISSING_TOOL=4
ERR_INVALID_OPTION=5

# Be talkative by default
# 2 = verbose
# 1 = error messages
# 0 = silent
QUIET=2

usage()
{
    cat << EOT
Usage: $(basename "$0") [-q|-qq]
    -q      suppress informational messages
    -qq     suppress all output
EOT

    error_exit "$@"
}

info()
{
    if (( "$QUIET" < 2 ));
    then
        return 0
    fi

    echo "$@" >&1
}

error_exit()
{
    local EXITCODE=$1
    shift

    if (( "$QUIET" > 0 ));
    then
        echo "$@" >&2
    fi

    exit "$EXITCODE"
}

if (( $# > 0 )); then
    case "$1" in
        -qq) QUIET=0 ;;
        -q) QUIET=1 ;;
        *) usage $ERR_INVALID_OPTION "Invalid option: $1" ;;
    esac
fi

check_home()
{
    if [[ "$HOME" == "" ]];
    then
        error_exit $ERR_HOME_PATH_UNKNOWN "Unable to find user home."
    fi

    return 0
}

check_dest()
{
    if [[ "$DEST" == "" ]] || [[ ! -d "$DEST" ]];
    then
        error_exit $ERR_DEST_DIR_MISSING "Destination directory not found or not a directory: $DEST"
    fi

    return 0
}

check_tools()
{
    if ! which -s md5
    then
        error_exit $ERR_MISSING_TOOL "md5 not found"
    fi

    if ! which -s curl
    then
        error_exit $ERR_MISSING_TOOL "curl not found"
    fi
}

curl_fetch()
{
    local URL="$1"
    local DEST="$2"

    if ! curl -s "$URL" 2>/dev/null > "$DEST"
    then
        error_exit $ERR_DOWNLOAD_FAILED "Failed to fetch $URL"
    fi

    return 0
}

checksums_match()
{
    local FILEA="$1"
    local FILEB="$2"

    if [[ ! -f "$FILEA" ]] || [[ ! -f "$FILEB" ]];
    then
        return 1
    fi

    if [[ "$(md5 -q "$FILEA")" != "$(md5 -q "$FILEB")" ]];
    then
        return 1
    fi

    return 0
}

install_script()
{
    local FROM="$1"
    local TO="$2"
    local BAK="$TO.prev"

    if [[ -f "$TO" ]];
    then
        cp "$TO" "$BAK"
    fi

    cp "$FROM" "$TO"

    return 0
}

update_or_install_script()
{
    local SCRIPT="$1"
    local SRC="$URLSTEM/$SCRIPT"
    local TMPFILE="$(mktemp -t "$SCRIPT")"
    local DESTFILE="$DEST/$SCRIPT"

    curl_fetch "$SRC" "$TMPFILE"

    if checksums_match "$TMPFILE" "$DESTFILE"
    then
        info "$SCRIPT is already up to date"
    else
        install_script "$TMPFILE" "$DESTFILE"
        info "$SCRIPT was installed or updated"
    fi

    rm "$TMPFILE"

    return 0
}

check_home
check_dest
check_tools

for SCRIPT in ${SCRIPTS[*]}; do update_or_install_script "$SCRIPT"; done

info "All done"
exit 0
