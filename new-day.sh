#!/bin/sh

usage_and_exit() {
  echo "Usage:"
  echo "./new-day.sh DAYNUMBER"
  [ -n "$1" ] && {
    echo
    echo "$1"
  }
  exit
}

DAY=$1
[ -z "$DAY" ] && {
  usage_and_exit "Missing DAYNUMBER"
}

case $DAY in
  ''|*[!0-9]*)
    usage_and_exit "DAYNUMBER is not a number, got ${DAY}"
    ;;
  *)
esac

pushd $(dirname "${0}") >/dev/null
. "${PWD}/secrets.sh"
[ ! -f "day-${DAY}.porth" ] && {
  cp boiler-plate.porth "day-${DAY}.porth"
  curl --silent "https://adventofcode.com/2021/day/${DAY}/input" -H "COOKIE: session=${SESSION_COOKIE}" > "inputs/day-${DAY}.input"
  touch "outputs/day-${DAY}.output"
  vim "inputs/day-${DAY}.example"
}
vim "outputs/day-${DAY}.example"
git add "day-${DAY}.porth" "inputs/day-${DAY}.*" "outputs/day-${DAY}.*"
vim "day-${DAY}.porth"
popd >/dev/null
