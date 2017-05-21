#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh" || exit 1


oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
}

exit 0

checkSplitting() {
	local expected found path
	path="$1"
	expected="$2"

	result="$(split_filepath "$path")"
	assertLastCommandSucceeded
	assertEquals "Split '${path}'" "$expected" "$result"
}

testSplittings() {
	local expected found path

	checkSplitting "/" "
/

"

	checkSplitting "/home/me/" "
/home/me

"

	checkSplitting "/home/me/file" "file
/home/me
file
"

	checkSplitting "/home/me/file.tar" "file.tar
/home/me
file
tar"

	checkSplitting "/home/me/file.tar.gz" "file.tar.gz
/home/me
file.tar
gz"

	checkSplitting "/home/me/.hidden" ".hidden
/home/me
.hidden
"

	checkSplitting "/home/me/.hidden.tar" ".hidden.tar
/home/me
.hidden
tar"

	checkSplitting "/home/me/.hidden.tar.gz" ".hidden.tar.gz
/home/me
.hidden.tar
gz"

	checkSplitting "/home/me/.." "..
/home/me
..
"

	checkSplitting "." "
.

"

}


runTests
