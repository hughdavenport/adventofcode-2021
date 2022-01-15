#!/bin/bash
FAIL=0
FAILED=()
SIMULATE=0
TIMEOUT="5m"

# Colors for printing pass/fail
GREEN=$(tput setaf 64)
RED=$(tput setaf 160)
RESET=$(tput sgr0)
pass() {
  echo "${GREEN}PASS${RESET}"
}
fail() {
  FAIL=1
  FAILED+=("${1}")
  echo "${RED}FAIL${RESET}"
}

test_input() {
  EXE="${1}"
  INPUT_PREFIX="${2}"
  OUTPUT_PREFIX="${3}"
  DIFF_TMP=$(mktemp)
  TYPE="${4}"
  if [[ "${TYPE}" =~ ^example(-[0-9][0-9]*)?$ ]]; then
    INPUT_FILE="${INPUT_PREFIX}.${TYPE}"
    OUTPUT_FILE="${OUTPUT_PREFIX}.${TYPE}"
  else
    INPUT_FILE="${INPUT_PREFIX}.input"
    OUTPUT_FILE="${OUTPUT_PREFIX}.output"
  fi
  echo -n "Testing running against ${TYPE} input: "
  if [ -s "${INPUT_FILE}" ]; then
    OUTPUT_TMP=$(mktemp)
    timeout --foreground ${TIMEOUT} ${EXE} < "${INPUT_FILE}" > "${OUTPUT_TMP}"
    RET=$?
    [ $RET -eq 0 ] && {
      cat "${OUTPUT_TMP}" | diff - "${OUTPUT_FILE}" > $DIFF_TMP
      [ $? -eq 0 ] && pass || {
        fail "${EXE} < ${INPUT_FILE}     # Diff"
        cat $DIFF_TMP
      }
    } || {
      [ $RET -eq 124 ] && {
        fail "${EXE} < ${INPUT_FILE}     # Timeout"
        echo "Timeout"
      } || {
        fail "${EXE} < ${INPUT_FILE}     # Ret $RET"
        echo "Bad return $RET"
      }
    }
    rm "${OUTPUT_TMP}"
  else
    fail "${EXE} < ${INPUT_FILE}     # No input file"
    echo "No input file"
  fi
  rm $DIFF_TMP
}

# Wrapper function to test against inputs
test_inputs() {
  EXE="${1}"
  INPUT_PREFIX="${2}"
  OUTPUT_PREFIX="${3}"
  TIMETMP=$(mktemp)
  [ -z "${4}" -o "${4}" = "example" ] && {
    { time test_input "${EXE}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "example"; } 2>${TIMETMP}
    cat ${TIMETMP} | tail -3 | head -1
  }
  for I in `seq 2 99`; do
    [ -f "${INPUT_PREFIX}.example-${I}" ] && [ -z "${4}" -o "${4}" = "example" -o "${4}" = "example-${I}" ] && {
      { time test_input "${EXE}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "example-${I}"; } 2>${TIMETMP}
      cat ${TIMETMP} | tail -3 | head -1
    }
  done
  [ -z "${4}" -o "${4}" = "actual" ] && {
    { time test_input "${EXE}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "actual"; } 2>${TIMETMP}
    cat ${TIMETMP} | tail -3 | head -1
  }
  rm ${TIMETMP}
}

PORTH="${HOME}/src/porth/porth"
START=01
END=25
[ -n "$1" ] && case $1 in ''|*[!0-9]*) ;; *) START=$1; END=$1; ;; esac
for DAY in $(seq -w "${START}" "${END}"); do
  PORTH_FILE="day-${DAY}.porth"
  [ ! -s "$PORTH_FILE" ] && {
    # Day not started
    continue
  }
  INPUT_PREFIX="inputs/day-${DAY}"
  OUTPUT_PREFIX="outputs/day-${DAY}"
  echo -n "Testing compiling ${PORTH_FILE} against porth.porth: "
  rm ./output 2>/dev/null; ${PORTH} com -s "$PORTH_FILE"
  if [ $? -eq 0 -a -x ./output ]; then
    pass
    test_inputs "./output" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "${2}"
    [ $SIMULATE -eq 1 ] && {
      echo "Testing sim mode"
      test_inputs "${PORTH} sim ${PORTH_FILE}" "${INPUT_PREFIX}" "${OUTPUT_PREFIX}" "${2}"
    }
  else
    fail "${PORTH} com -s \"$PORTH_FILE\""
  fi
done
echo -n "Overall: "
[ $FAIL -eq 0 ] && pass || fail
for I in `seq 0 ${#FAILED[@]}`; do
  echo ${FAILED[$I]}
done
exit $FAIL
