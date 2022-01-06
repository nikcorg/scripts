#!/usr/bin/env bash

set -eu

if ! which -s curl || ! which -s pup || ! which -s jq || ! which -s recode; then
  printf "\033[0merror: %s requires \033[33mcurl\033[0m, \033[33mpup\033[0m, \033[33mjq\033[0m and \033[33mrecode\033[0m to be available in \$PATH\n" "$(basename "$0")" >&2
  exit 1
fi

days=1
global_offset=0
offset=0
highlight=""
highlight_lc=""

function usage() {
  # shellcheck disable=SC2155
  local usage=$(cat <<EOT
usage: %s [-h] [-o <n>] [-n <n>] [-f <term>]

  -h        this help
  -n <n>    number of days to display
  -o <n>    number of days to offset
  -f <term> term to highlight in the results, requires exact match

  <n> should be a numeric argument
EOT
)
  # shellcheck disable=SC2059
  printf "$usage\n" "$(basename "$0")" >&2
}

if (( $# > 0 )); then
  while getopts ":hf:n:o:" flag "$@"; do
    case "$flag" in
      f)
        highlight="$OPTARG"
        highlight_lc="$(tr '[:upper:]' '[:lower:]' <<<"$highlight")"
        ;;
      o)
        global_offset="$OPTARG"
        ;;
      n)
        days="$OPTARG"
        ;;
      h)
        usage
        exit 0
        ;;
      *)
        if [[ "$flag" == ":" ]]; then
          printf "error: -%s requires an argument\n" "$OPTARG" >&2
        else
          printf "error: unknown option: -%s\n" "$OPTARG" >&2
        fi
        usage
        exit 1
    esac
  done
  shift $((OPTIND-1))
fi

tempfile=$(mktemp)
source_url="https://www.thewhiskyexchange.com/new-products/standard-whisky"
href_prefix="https://www.thewhiskyexchange.com"
entry_matcher="li.np-postlist__item:nth-child($((offset + 1)))"

function fetch() {
  curl -s "$source_url" > "$tempfile"
}

function number_of_entries() {
  pup -n -f "$tempfile" "$entry_matcher a"
}

function extract_title() {
  pup -f "$tempfile" "$entry_matcher a json{}" | jq -r ".[$1].title|ltrimstr(\" \")" | recode HTML..UTF8
}

function extract_href() {
  printf "%s%s" "$href_prefix" "$(pup -f "$tempfile" "$entry_matcher a json{}" | jq -r ".[$1].href")"
}

function extract_day() {
  pup -f "$tempfile" "$entry_matcher .np-posthead__date .np-posthead__date-day json{}" | jq -r '.[].text'
}

function extract_date() {
  local format="%b %d"
  # shellcheck disable=SC2155
  local month="$(extract_month)"
  # shellcheck disable=SC2155
  local day="$(extract_day | cut -d '-' -f 1)"

  if (( $# > 0 )); then
    format="$1"
  fi

  date -jf '%B %d %T' "$month $day 00:00:00" +"$format"
}

function extract_month() {
  pup -f "$tempfile" "$entry_matcher .np-posthead__date .np-posthead__date-month json{}" | jq -r '.[].text'
}

function extract_description() {
  pup -f "$tempfile" "$entry_matcher .np-posthead__copy p json{}" | jq -r '.[].text' | recode HTML..UTF8
}

function time_since() {
  # shellcheck disable=SC2155
  local now=$(date +"%s")
  local then="$1"
  local days=$(((now - then) / 86400))

  if [ $days -eq 0 ]; then
    echo "today"
  elif [ $days -eq 1 ]; then
    printf "yesterday"
  else
    printf "%d days ago" "$days"
  fi
}

function present() {
  # shellcheck disable=SC2155
  local entries=$(number_of_entries)
  local digits=1

  if (( entries > 9 )); then
    digits=2
  fi

  if (( entries == 0 )); then
    printf "No entries found for offset %d\n" "$offset"
    exit 0
  fi

  # shellcheck disable=SC2155
  local date_posted="$(extract_date)"
  # shellcheck disable=SC2155
  local since_posted="$(time_since "$(extract_date "%s")")"

  printf "\033[0mFound \033[33m%d\033[0m entries for \033[33m%s\033[0m (%s)\n\n" "$entries" "$date_posted" "$since_posted"
  printf "\033[96m%s\033[0m\n\n" "$(extract_description)"

  local title

  for n in $(seq 0 $((entries - 1))); do
    title="$(extract_title "$n")"
    title_lc="$(tr '[:upper:]' '[:lower:]' <<<"$title")"

    if [[ -n "$highlight" ]] && [[ "$title_lc" == *"$highlight_lc"* ]]; then
      em="$(printf "\033[45m%s\033[49m" "$highlight")"
      title="$(printf "👉  %s  👈" "${title/$highlight/$em}")"
    fi

    printf "%${digits}d. \033[93m%s\033[0m\n%${digits}s  \033[37m%s\033[0m\n" "$((n + 1))" "$title" "" "$(extract_href "$n")"
  done
}

fetch

for n in $(seq 1 $days); do
  offset=$((global_offset + n - 1))
  entry_matcher="li.np-postlist__item:nth-child($((offset + 1)))"
  present
  echo
done
