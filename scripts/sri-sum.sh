#!/usr/bin/env bash

if ! which openssl 2>&1 >/dev/null; then
  printf "error: %s requires openssl\n" "$(basename $0)" >&2
  exit 1
fi

function usage() {
  printf "usage: %s <filename>\n" "$(basename $0)" >&2
}

if [ $# -eq 0 ]; then
  usage
  exit 1
elif [ ! -f $1 ]; then
  printf "error: %s not found\n" "$1" >&2
  usage
  exit 1
fi

printf "sha384-%s" "$(cat $1 | openssl dgst -sha384 -binary | openssl base64 -A)"
