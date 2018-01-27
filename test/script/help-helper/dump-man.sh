#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}

testDumpSmartdogMan() {
	local man_text man_text_made_static expected_man_text

	expected_man_text="$(cat "${test_resources_dir}/smartdog-expected.man")"

	man_text="$("${test_common_resources_dir}/smart_dog.sh" help --dump-man)"
	assertLastCommandSucceeded
	man_text_made_static="$(sed 's/^\(\.TH smart_dog\.sh 1 \"\)\(.\+\)\(\" \"version 1.0\"\)$/\1SOME_DATE\3/' <<< "$man_text")"
	assertEquals "Generated man is correct" "$expected_man_text" "$man_text_made_static"

	echo "$man_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.man"
	echo "$man_text_made_static" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog-man_made_static.man"
}

runTests
