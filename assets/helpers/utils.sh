#!/bin/bash

export TMPDIR=${TMPDIR:-/tmp}

hash() {
  sha=$(which sha256sum || which shasum)
  echo "$1" | $sha | awk '{ print $1 }'
}

contains_element() {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

hide_password() {
  if ! echo "$1" | jq -c '.' > /dev/null 2> /dev/null; then
    echo "(invalid json: $1)>"
    exit 1
  fi

  local paths=$(echo "${1:-{\} }" | jq -c "paths")
  local query=""
  if [ -n "$paths" ]; then
    while read path; do
      local parts=$(echo "$path" | jq -r '.[]')
      local selection=""
      local found=""
      while read part; do
        selection+=".$part"
        if [ "$part" == "password" ]; then
          found="true"
        fi
      done <<< "$parts"

      if [ -n "$found" ]; then
        query+=" | jq -c '$selection = \"*******\"'"
      fi
    done <<< "$paths"
  fi

  local json="${1//\"/\\\"}"
  eval "echo \"$json\" $query"
}

log() {
  # $1: message
  # $2: json
  local message="$(date -u '+%F %T') - $1"
  if [ -n "$2" ]; then
   message+=" - $(hide_password "$2")"
  fi
  echo -e "$message" >&2
}

tmp_file() {
  echo "$TMPDIR/bitbucket-pullrequest-resource-$1"
}

tmp_file_unique() {
  mktemp "$TMPDIR/bitbucket-pullrequest-resource-$1.XXXXXX"
}

date_from_epoch_seconds() {
  # Mac OS X:
  #date -r $1
  date -d @$1
}

# http://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done

  echo "${encoded}"
}

regex_escape() {
  echo "$1" | sed 's/[^^]/[&]/g; s/\^/\\^/g'
}

getBasePathOfBitbucket() {
  # get base path in case bitbucket does not run on /

  local base_path=""
  for i in "${!uri_parts[@]}"
  do
    if [ ${uri_parts[$i]} = "scm" ]; then
      break
    fi

    base_path=$base_path"/"${uri_parts[$i]}
  done

  echo ${base_path}
}
