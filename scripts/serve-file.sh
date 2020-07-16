#!/usr/bin/env bash

# Serve a file as HTTP response using netcat

set -eu

# Error outcomes
EX_UNAVAILABLE=69

# Initial values
PROGRAM_NAME=$(basename $0)
SERVE_FILE=""
CONTENT_LENGTH="0"
CONTENT_TYPE=""
CONTENT_ENCODING=""
DUMP_CONFIG="no"
RESP_FILE=$(mktemp -t $PROGRAM_NAME)
FALLBACK_CONTENT_TYPE="application/octet-stream"
FALLBACK_ENCODING="utf-8"
NETCAT_FLAGS="-l"

NC='\033[0m'        # no colour
LBLUE='\033[1;34m'  # light blue
LGREY='\033[0;37m'  # light grey
RED='\033[1;31m'    # red
YELLOW='\033[1;33m' # yellow

ca() { echo -e "$LBLUE"; }     # accent colour
cb() { echo -e "$LGREY"; }     # base colour
ce() { echo -e "$RED"; }       # error colour
ch() { echo -e "$YELLOW"; }    # highlight colour
cr() { echo -e "$NC"; }        # reset colour

usage() {
  # This heredoc *must* be indented using tabs
  cat >&2 <<-EOUSAGE
	$(cr)usage: $(ch)${PROGRAM_NAME}$(cr) [$(ca)-h$(cr)] [$(ca)-d$(cr)] [$(ca)-a$(cr)] [$(ca)-p$(cr) $(cb)<port>$(cr)] [$(ca)-m$(cr) $(cb)<mime-type>$(cr)] [$(ca)-e$(cr) $(cb)<charset>$(cr)] [$(ca)-s$(cr) $(cb)<http status>$(cr)] $(ch)<file>$(cr) $(cb)[-- <netcat options>]$(cr)
	    $(cb)-h                - this help
	    $(cb)-p <port>         - defaults to $(ca)8080$(cr)
	    $(cb)-m <mime-type>    - defaults to auto-detect with a fallback to $(ca)$FALLBACK_CONTENT_TYPE$(cr)
	    $(cb)-e <charset>      - defaults to $(ca)$FALLBACK_ENCODING$(cr)
	    $(cb)-s <http status>  - defaults to $(ca)200 OK$(cr)
	    $(cb)-d                - dump config on startup$(cr)
	    $(cb)--                - stop reading options and passthru anything following directly to nc$(cr)

	$(cb)${PROGRAM_NAME} generates an HTTP response for a file and uses netcat to serve it. Anything following '$(ca)--$(cb)' will be passed directly to $(ca)nc$(cr).
	EOUSAGE
}

PARSE_OWN_ARGS=0
if [ $# -eq 0 ]; then
  usage
  exit 1
else
  while [ $# -gt 0 ]; do
    if [[ $PARSE_OWN_ARGS -eq 0 ]]; then
      case $1 in
        --)
          PARSE_OWN_ARGS=1
          ;;
        -d)
          DUMP_CONFIG="yes"
          ;;
        -e)
          shift
          CONTENT_ENCODING="$1"
          ;;
        -h)
          usage
          exit 0
          ;;
        -m)
          shift
          CONTENT_TYPE="$1"
          ;;
        -p)
          shift
          PORT="$1"
          ;;
        -s)
          shift
          RESPONSE_STATUS="$1"
          ;;
        *)
          SERVE_FILE="$1"
          ;;
      esac
    else
      NETCAT_FLAGS="$NETCAT_FLAGS $1"
    fi
    shift
  done
fi

serve-nc() {
  set -- nc "$NETCAT_FLAGS" "$PORT"

  echo "running $@"

  eval "$@" < $RESP_FILE | sed -e 's/^/[nc] /'
}

generate-resp() {
  local clen=$(wc -c "$SERVE_FILE" | awk '{ print $1 }')

  # This heredoc *must* be indented using tabs
  cat > $RESP_FILE <<-EORESP
	HTTP/1.1 ${RESPONSE_STATUS}
	Content-Type: ${CONTENT_TYPE}; charset=${CONTENT_ENCODING}
	Content-Length: ${clen}

	EORESP
  cat "$SERVE_FILE" >> $RESP_FILE
}

dump-config() {
  if [ $DUMP_CONFIG = "no" ]; then
    return
  fi

  printf "$(cr)-- config dump --\n" >&2

	cat >&2 <<-EOPOOP
	$(cb)RESPONSE_STATUS$(cr)  = $(ca)$RESPONSE_STATUS$(cr)
	$(cb)CONTENT_TYPE$(cr)     = $(ca)$CONTENT_TYPE$(cr)
	$(cb)CONTENT_ENCODING$(cr) = $(ca)$CONTENT_ENCODING$(cr)
	$(cb)PORT$(cr)             = $(ca)$PORT$(cr)
	$(cb)SERVE_FILE$(cr)       = $(ca)$SERVE_FILE$(cr)
	$(cb)NETCAT_FLAGS$(cr)     = $(ca)$NETCAT_FLAGS$(cr)

	EOPOOP

  printf "$(ca)HTTP response$(cr) $(cb)(sans file content)$(cr) is:\n" >&2
  head -3 $RESP_FILE >&2

  printf "$(cr)-- end of config dump --\n" >&2
}

probe-content-type() {
  if ! which -s file; then
    printf "$(cr)%s: $(ca)file$(cr) program not found, unable to auto-detect content-type or encoding: defaulting to $(ca)%s$(cr) and $(ca)%s$(cr)\n" "$PROGRAM_NAME" "${CONTENT_TYPE:-$FALLBACK_CONTENT_TYPE}" "${CONTENT_ENCODING:-FALLBACK_ENCODING}" >&2
    echo "$FALLBACK_CONTENT_TYPE"
    return 0
  fi

  local probe=$(file -b --mime-type --mime-encoding "$SERVE_FILE")
  local ct=$(echo "$probe" | cut -d ";" -f 1)
  local ce=$(echo "$probe" | cut -d "=" -f 2)

  if [ -z "$CONTENT_TYPE" ]; then
    CONTENT_TYPE="$ct"
  fi

  if [ -z "$CONTENT_ENCODING" ]; then
    CONTENT_ENCODING="$ce"
  fi
}

check-config() {
  # Auto-detect content-type if not provided
  if [ -z "$CONTENT_TYPE" -o -z "$CONTENT_ENCODING" ]; then
    probe-content-type
  fi

  # Assign defaults to unset configuratble values
  : ${RESPONSE_STATUS:="200 OK"}
  : ${CONTENT_TYPE:="$FALLBACK_CONTENT_TYPE"}
  : ${CONTENT_ENCODING:="$FALLBACK_ENCODING"}
  : ${PORT:="8080"}

  if [ -z "$SERVE_FILE" ]; then
    usage
    exit 1
  elif [ ! -f "$SERVE_FILE" ]; then
    printf "$(cr)%s: $(ch)%s$(cr): file not found\n" "$PROGRAM_NAME" "$SERVE_FILE" >&2
    exit $EX_UNAVAILABLE
  fi
}

serve() {
  printf "$(cr)%s: serving $(ch)%s$(cr) as $(ca)%s$(cr) encoded as $(ca)%s$(cr) on port $(ca)%d$(cr)\n" "$PROGRAM_NAME" "$SERVE_FILE" "$CONTENT_TYPE" "$CONTENT_ENCODING" "$PORT" >&2
  printf "$(cr)%s: hit $(ch)^C$(cr) to stop\n" "$PROGRAM_NAME" >&2

  while true; do
    if ! serve-nc; then
      printf "$(cr)%s: stopping, $(ca)netcat$(cr) exited with an error status\n" "$PROGRAM_NAME" >&2
      exit 1
    fi
  done
}

check-config
generate-resp
dump-config
serve
