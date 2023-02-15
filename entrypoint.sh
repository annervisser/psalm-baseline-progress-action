#!/bin/sh

set -euv

ls -alh

#echo current:
#git show "$GITHUB_REF:psalm-baseline.xml" | xmllint --xpath 'count(//file[not(starts-with(@src, "test"))]/*/code)' -
#echo old:
#git show "$GITHUB_BASE_REF:psalm-baseline.xml" | xmllint --xpath 'count(//file[not(starts-with(@src, "test"))]/*/code)' -
