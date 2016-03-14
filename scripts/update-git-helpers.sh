#!/bin/bash

# Usage: simply run the script,
# add -q for info message suppression
# add -qq for all output suppression

# If you plan to run this script using cron and you feel unsure of
# your cron environment, uncomment the line below and edit the path
#HOME="<path to your home directory here>"

# A space separated list of scripts to keep updated, for options see:
# https://github.com/git/git/tree/master/contrib/completion
SCRIPTS="git-completion.bash git-prompt.sh"

# Where to place the downloaded scripts
DEST="$HOME/bin"

# Where to download the scripts from
URLSTEM="https://raw.githubusercontent.com/git/git/master/contrib/completion"

# Required programs
MD5=$(which -s md5; echo $?)
CURL=$(which -s curl; echo $?)

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
Usage: $(basename $0) [-q|-qq]
    -q      suppress informational messages
    -qq     suppress all output
EOT

    error_exit "$@"
}

info()
{
    if [ $QUIET -lt 2 ];
    then
        return 0
    fi

    echo "$@" >&1
}

error_exit()
{
    local EXITCODE=$1
    shift

    if [ $QUIET -gt 0 ];
    then
        echo "$@" >&2
    fi

    exit $EXITCODE
}

if [ ! -z "$1" -a "$1" = "-qq" ];
then
    QUIET=0
elif [ ! -z "$1" -a "$1" = "-q" ];
then
    QUIET=1
elif [ ! -z "$1" ];
then
    usage $ERR_INVALID_OPTION "Invalid option: $1"
fi

check_home()
{
    if [ "x$HOME" = "x" ];
    then
        error_exit $ERR_HOME_PATH_UNKNOWN "Unable to find user home."
    fi

    return 0
}

check_dest()
{
    if [ "x$DEST" = "x" -o ! -d "$DEST" ];
    then
        error_exit $ERR_DEST_DIR_MISSING "Destination directory not found or not a directory: $DEST"
    fi

    return 0
}

check_tools()
{
    if [ $MD5 -ne 0 ];
    then
        error_exit $ERR_MISSING_TOOL "md5 not found"
    fi

    if [ $CURL -ne 0 ];
    then
        error_exit $ERR_MISSING_TOOL "curl not found"
    fi
}

curl_fetch()
{
    local URL="$1"
    local DEST="$2"

    curl -s "$URL" 2>/dev/null > "$DEST"

    local CURLEXIT=$?

    if [ "x$CURLEXIT" != "x0" -o ! -f "$TMPFILE" ];
    then
        error_exit $ERR_DOWNLOAD_FAILED "Failed ($CURLEXIT) to fetch $URL"
    fi

    return $CURLEXIT
}

checksums_match()
{
    local FILEA="$1"
    local FILEB="$2"

    if [ ! -f "$FILEA" -o ! -f "$FILEB" ];
    then
        return 1
    fi

    local CSA=$(md5 -q "$FILEA")
    local CSB=$(md5 -q "$FILEB")

    if [ "$CSA" != "$CSB" ];
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

    if [ -f "$TO" ];
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
    local TMPFILE="/tmp/$SCRIPT"
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

for SCRIPT in $SCRIPTS; do update_or_install_script "$SCRIPT"; done

info "All done"
exit 0
