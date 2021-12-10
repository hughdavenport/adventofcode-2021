#!/bin/sh
FAIL=0

# Colors for printing pass/fail
GREEN=$(tput setaf 64)
RED=$(tput setaf 160)
RESET=$(tput sgr0)
pass() {
  echo "${GREEN}PASS${RESET}"
}
fail() {
  FAIL=1
  echo "${RED}FAIL${RESET}"
}

test_input() {
  EXE="${1}"
  INPUT_PREFIX="${2}"
  OUTPUT_PREFIX="${3}"
  DIFF_TMP=$(mktemp)
  TYPE="${4}"
  if [ "${TYPE}" = "example" ]; then
    INPUT_FILE="${INPUT_PREFIX}.${TYPE}"
    OUTPUT_FILE="${OUTPUT_PREFIX}.${TYPE}"
  else
    INPUT_FILE="${INPUT_PREFIX}.input"
    OUTPUT_FILE="${OUTPUT_PREFIX}.output"
  fi
  echo -n "Testing running against ${TYPE} input: "
  if [ -s "${INPUT_FILE}" ]; then
    ${EXE} < "${INPUT_FILE}" | diff - "${OUTPUT_FILE}" > $DIFF_TMP
    [ $? -eq 0 ] && pass || {
      fail
      cat $DIFF_TMP
    }
  else
    fail
    echo "No input file"
  fi
  rm $DIFF_TMP
}

# Wrapper function to test against inputs
test_inputs() {
  EXE="${1}"
  INPUT_PREFIX="${2}"
  OUTPUT_PREFIX="${3}"
  [ -z "${4}" -o "${4}" = "example" ] && test_input "${EXE}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "example"
  [ -z "${4}" -o "${4}" = "actual" ] && test_input "${EXE}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "actual"
}

PORTH="${HOME}/src/porth/porth"
PORTH_PY="${HOME}/src/porth/porth.py"
START=1
END=25
[ -n "$1" ] && case $1 in ''|*[!0-9]*) ;; *) START=$1; END=$1; ;; esac
for DAY in $(seq "${START}" "${END}"); do
  PORTH_FILE="day-${DAY}.porth"
  [ ! -s "$PORTH_FILE" ] && {
    # Day not started
    continue
  }
  INPUT_PREFIX="inputs/day-${DAY}"
  OUTPUT_PREFIX="outputs/day-${DAY}"
  echo -n "Testing compiling ${PORTH_FILE} against porth.porth: "
  ${PORTH} com -s "$PORTH_FILE"
  if [ $? -eq 0 ]; then
    pass
    test_inputs "./output" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "${2}"
  else
    fail
    echo "here"
  fi
  echo -n "Testing compiling ${PORTH_FILE} against porth.py: "
  ${PORTH_PY} com -s "$PORTH_FILE"
  if [ $? -eq 0 ]; then
    pass
    test_inputs "./day-${DAY}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "${2}"
  else
    fail
    echo "here"
  fi
done
echo -n "Overall: "
[ $FAIL -eq 0 ] && pass || fail
exit $FAIL
