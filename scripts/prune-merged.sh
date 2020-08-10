#!/usr/bin/env bash

OMIT_CONFIRM=1

if [ $# -gt 0 ] && [ "$1" = "-y" ]; then
  OMIT_CONFIRM=0
elif [ $# -gt 0 ]; then
  echo "Unknown argument: \"$1\"" >&2
  echo "Usage: $(basename $0) [-y]" >&2
  echo " -y   Skip confirm prune" >&2
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
OMITPATTERN="master\|legacy\|$CURRENT_BRANCH"
BRANCHES=$(git branch --merged | grep -v "$OMITPATTERN" | awk '{ print $1 }')

confirm() {
  echo -n "$1 (Y/n) "
  read -n 1
  echo

  if [[ "$REPLY" == "y" || "$REPLY" == "Y" || "$REPLY" == "" ]]; then
    return 0
  fi

  return 1
}

if [[ $BRANCHES != "" ]]; then
  for BRANCH in $BRANCHES; do
    if [ $OMIT_CONFIRM -eq 0 ] || confirm "Prune $BRANCH"; then
      if [ $OMIT_CONFIRM -eq 0 ]; then
        echo "Pruning $BRANCH"
      fi

      git branch -d "$BRANCH" 1> /dev/null
    fi
  done
else
  echo "Nothing to prune"
fi
