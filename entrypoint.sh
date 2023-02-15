#!/bin/sh

set -euv

env

#echo current:
#git show "HEAD:psalm-baseline.xml" | xmllint --xpath 'count(//file[not(starts-with(@src, "test"))]/*/code)' -
#echo old:
#git show "${{ github.base_ref }}:psalm-baseline.xml" | xmllint --xpath 'count(//file[not(starts-with(@src, "test"))]/*/code)' -
