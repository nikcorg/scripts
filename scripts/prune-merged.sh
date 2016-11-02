#!/usr/bin/env bash

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
OMITPATTERN="master\|$CURRENT_BRANCH"
BRANCHES=$(git branch --merged | grep -v "$OMITPATTERN" | awk '{ print $1 }')
BRANCHES_FOUND=$?

confirm() {
  echo "$1 (Y/n)"
  read -sn 1

  if [[ "$REPLY" == "y" || "$REPLY" == "Y" ]]; then
    return 0
  fi

  return 1
}

if [[ $BRANCHES_FOUND ]]; then
  echo "Found pruneable branches:"
  for BRANCH in $BRANCHES; do
    if confirm "Prune $BRANCH"; then
      git branch -d "$BRANCH"
    fi
  done
else
  echo "Nothing to prune"
fi
