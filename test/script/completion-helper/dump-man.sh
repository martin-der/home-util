#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}

testDumpMan() {
	local man_text expected_man_text

	expected_man_text=".TH smart_dog.sh 1 \"TODAY\" \"version 1.0\"
.SH NAME
smart_dog.sh - Dog interaction for newbies
.SH SYNOPSIS
.B smart_dog.sh
fetch
what...
.br
.B smart_dog.sh
bark
sound...
.br
.B smart_dog.sh
sleep
duration...
.br
.B smart_dog.sh
smell
.br
.B smart_dog.sh
call
name...
.SH DESCRIPTION
This application helps you to interact with you dog.
"

	man_text="$("${test_root_dir}/resources/smart_dog.sh" help --dump-man)"
	return 0
	assertLastCommandSucceededsdq
	assertEquals "Generated man is correct" "$expected_man_text" "$man_text"

	echo "$man_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.man"
}

runTests
