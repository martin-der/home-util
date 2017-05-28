#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}

testDumpMan() {
	local man_text man_text_made_static expected_man_text

	expected_man_text=".TH smart_dog.sh 1 \"SOME_DATE\" \"version 1.0\"
.SH NAME
smart_dog.sh - Dog interaction for newbies
.SH SYNOPSIS
.B smart_dog.sh
fetch
.br
.B smart_dog.sh
hold
.br
.B smart_dog.sh
bark
.br
.B smart_dog.sh
sleep
.br
.B smart_dog.sh
smell
.br
.B smart_dog.sh
call
.SH DESCRIPTION
This application helps your to interact with you dog."

	man_text="$("${test_root_dir}/resources/smart_dog.sh" help --dump-man)"
	assertLastCommandSucceeded
	man_text_made_static="$(sed 's/^\(\.TH smart_dog\.sh 1 \"\)\(.\+\)\(\" \"version 1.0\"\)$/\1SOME_DATE\3/' <<< "$man_text")"
	assertEquals "Generated man is correct" "$expected_man_text" "$man_text_made_static"

	echo "$man_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.man"
	echo "$man_text_made_static" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog-man_made_static.man"
}

runTests
