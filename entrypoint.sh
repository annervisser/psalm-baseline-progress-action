#!/usr/bin/env sh

set -eu

# Mark the checkout as safe
git config --global --add safe.directory /github/workspace

# Log inputs for debugging
echo "::debug::BASE: $BASE_REF"
echo "::debug::HEAD: $HEAD_REF"
echo "::debug::PATH_TO_BASELINE: $PATH_TO_BASELINE"

get_baseline_score() {
  if ! BASELINE_XML=$(git show "$1"); then
    echoerr "::error ::No baseline found at $1" 1>&2
    return 1
  fi

  if ! BASELINE_SCORE=$(echo "$BASELINE_XML" | xmllint --xpath 'count(//file[not(starts-with(@src, "test"))]/*/code)' -); then
    echoerr "::error ::Unable to parse baseline at $1" 1>&2
    return 1
  fi

  echo "$BASELINE_SCORE"
}

# Fetch if needed
git reflog "$HEAD_REF" 2>/dev/null || git fetch --depth=1 origin "$HEAD_REF"
# Get score
HEAD_SCORE=$(get_baseline_score "$HEAD_REF:$PATH_TO_BASELINE")
echo "head_score: $HEAD_SCORE"

# Fetch if needed
git reflog "$BASE_REF" 2>/dev/null || git fetch --depth=1 origin "$BASE_REF"
# Get score
BASE_SCORE=$(get_baseline_score "$BASE_REF:$PATH_TO_BASELINE")
echo "base_score: $BASE_SCORE"

# Check if scores are different
SCORE_DIFF=$((HEAD_SCORE - BASE_SCORE))
SCORE_DIFF_STRING=$(printf '%+d' $SCORE_DIFF)

# Process templates
TEMPLATE=''
if [ $SCORE_DIFF -gt 0 ]; then
  TEMPLATE="$TEMPLATE_INCREASED"
elif [ $SCORE_DIFF -lt 0 ]; then
  TEMPLATE="$TEMPLATE_DECREASED"
else
  TEMPLATE="$TEMPLATE_NO_CHANGE"
fi

export BASE_SCORE HEAD_SCORE SCORE_DIFF SCORE_DIFF_STRING
# shellcheck disable=SC2016
OUTPUT_MESSAGE=$(echo "$TEMPLATE" | envsubst '$BASE_SCORE $HEAD_SCORE $SCORE_DIFF $SCORE_DIFF_STRING')

# Set outputs
{
  echo "base_score=$BASE_SCORE"
  echo "head_score=$HEAD_SCORE"
  echo "score_diff=$SCORE_DIFF"
  echo "score_diff_string=$SCORE_DIFF_STRING"
} >>"$GITHUB_OUTPUT"

# Output message could be multiline, use heredoc
{
  echo "output_message<<EOF"
  echo "$OUTPUT_MESSAGE"
  echo "EOF"
} >>"$GITHUB_OUTPUT"
