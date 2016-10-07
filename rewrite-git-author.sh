#!/bin/sh

if [ "x$1" = "x" ]; then
    echo "Usage: $0 <old email>"
    exit 1
fi

if [ ! -d "./.git" ]; then
    echo "`pwd` is not a git repository"
    exit 1
fi

OLD_EMAIL=$1
CORRECT_NAME="Niklas Lindgren"
CORRECT_EMAIL="nikc@iki.fi"

git filter-branch -f --env-filter '
if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags
