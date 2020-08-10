#!/usr/bin/env bash

DUMP=/Users/developer/tmp/inspirobot
GENERATED_IMG_SRC=$(curl -s "https://inspirobot.me/api?generate=true")

if [ $? -eq 0 ]; then
  BASENAME=$(basename $GENERATED_IMG_SRC)
  OUT="$DUMP/$BASENAME"
  TMP="/tmp/$BASENAME"

  curl -s -o "$TMP" "$GENERATED_IMG_SRC"

  if [ $? -eq 0 ]; then
    MIME=$(file -b --mime-type $TMP)

    if [[ $MIME == image/* ]]; then
      mv "$TMP" "$OUT"
      osascript -e 'tell application "System Events" to set picture of every desktop to ("'$OUT'" as POSIX file as alias)'
    fi
  fi
fi
