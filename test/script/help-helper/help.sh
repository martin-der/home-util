#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}


testDumpHelp() {
	local help_text expected_help_text

	expected_help_text="$(cat "${test_resources_dir}/help-expected.txt")"

	help_text="$("${test_common_resources_dir}/smart_dog.sh" help)"
	assertLastCommandSucceeded
	assertEquals "Generated help is correct" "$expected_help_text" "$help_text"

	echo "$help_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/help.txt"
}



runTests

