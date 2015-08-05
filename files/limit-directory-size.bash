#!/bin/bash
# Limit directory size by deleting files accessed least recently.
#
# Use inotify to wait for files written to the specified directory. On such an
# event, and if the directory size is over the specified maximum size, keep
# deleting files until the size is below the maximum. Repeat (so, never exit).
#
# Names of deleted files are written to stdout, messages are prefixed with the
# string ">>>".
#
# Adaptation of: https://stackoverflow.com/questions/11618144
#
# 2014, Martijn Vermaat <m.vermaat.hg@lumc.nl>

set -o nounset
set -o errexit
set -o pipefail

if [[ -z "${1+present}" || -z "${2+present}" || "$2" -lt 1 ]]; then
    echo "Usage: $0 <directory> <max size>" >&2
    exit 1
fi

if ! hash inotifywait 2>/dev/null; then
    echo "$0: requires the inotifywait program" >&2
    exit 1
fi

DIR="$1"
MAX_SIZE="$2"

trap 'kill -- -$$' EXIT

inotifywait -m -r -q -e close_write -e moved_to --format "%e" "$DIR" \
| while read event; do

    SIZE="$(du -bs "$DIR" | cut -f 1)"

    if [[ "$SIZE" -lt "$MAX_SIZE" ]]; then
        # Size is below maximum size, do nothing.
        continue
    fi

    echo ">>> $(/bin/date)"
    echo ">>> $DIR is $SIZE bytes (max is $MAX_SIZE)"

    # Sort all files by last access time, most recently accessed first. Keep
    # adding their size and report the filename if we exceeded the maximum.
    # Finally remove all reported files, starting with the least recently
    # accessed.

    find "$DIR" -type f -printf "%A@::%p::%s\n" \
    | sort -rn \
    | awk -v max_bytes="$MAX_SIZE" -F "::" '
      BEGIN { total_bytes=0; }
      {
      total_bytes += $3;
      if (total_bytes > max_bytes) { print $2; }
      }
      ' \
    | tac | tee >(awk '{printf "%s%c",$0,0}' | xargs -0 -r rm)

    # Delete empty directories.
    find "$DIR" -mindepth 1 -depth -type d -empty -print -exec rmdir "{}" \;

done
