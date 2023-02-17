#!/usr/bin/env sh

set -eu

git config --global --add safe.directory /github/workspace

echoerr() { echo "$@" 1>&2; }

echo "::debug::BASE: $BASE_REF"
echo "::debug::HEAD: $HEAD_REF"
echo "::debug::PATH_TO_BASELINE: $PATH_TO_BASELINE"

get_baseline_score() {
  if ! BASELINE_XML=$(git show "$1"); then
    echoerr "::error ::No baseline found at $1"
    return 1
  fi

  if ! BASELINE_SCORE=$(echo "$BASELINE_XML" | xmllint --xpath 'count(//file[not(starts-with(@src, "test"))]/*/code)' -); then
    echoerr "::error ::Unable to parse baseline at $1"
    return 1
  fi

  echo "$BASELINE_SCORE"
}

git fetch --depth=1 origin "$HEAD_REF"
HEAD_SCORE=$(get_baseline_score "$HEAD_REF:$PATH_TO_BASELINE")
echo "head_score: $HEAD_SCORE"

git fetch --depth=1 origin "$BASE_REF"
BASE_SCORE=$(get_baseline_score "$BASE_REF:$PATH_TO_BASELINE")
echo "base_score: $BASE_SCORE"

echo "base_score=$BASE_SCORE" >> "$GITHUB_OUTPUT"
echo "head_score=$HEAD_SCORE" >> "$GITHUB_OUTPUT"
