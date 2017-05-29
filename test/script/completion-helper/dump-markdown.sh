#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}

testDumpSmartdogMarkdown() {
	local markdown_text expected_markdown_text

	expected_markdown_text="$(cat "${test_resources_dir}/smartdog-expected.md")"

	markdown_text="$("${test_common_resources_dir}/smart_dog.sh" help --dump-markdown)"
	assertLastCommandSucceeded
	assertEquals "$expected_markdown_text" "$markdown_text"

	echo "$markdown_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.md"
}

runTests
