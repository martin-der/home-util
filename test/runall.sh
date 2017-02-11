#!/bin/bash

find test/ \( -name shunit2* -o -name resources \) -prune -o -regex 'test/.*/.*\.sh' -exec echo '{}' \; | while read t ; do
	bash "$t" 2>/dev/null >/dev/null && echo "$t : Success" || echo "$t : Failure" 
done

