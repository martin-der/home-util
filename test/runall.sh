#!/usr/bin/env bash

all_tests=`find test/ -regex 'test/script/.*/.*\.sh' -exec echo '{}' \;`

IFS="\
"
all_successful=1
while read t ; do
	bash "$t" 2>/dev/null >/dev/null && echo "$t : Success" || { echo "$t : Failure" ; all_successful=0; }
done <<< ${all_tests}

[ ${all_successful} -eq 0 ] && exit 1 || exit 0

