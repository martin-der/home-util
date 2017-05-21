#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}

testDumpMarkdown() {
	local markdown_text expected_markdown_text

	expected_markdown_text="toto
=====
"

	markdown_text="$("${test_root_dir}/resources/smart_dog.sh" help --dump-markdown)"
	assertLastCommandSucceeded
	assertEquals "$expected_markdown_text" "$markdown_text"

	echo "$markdown_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.md"
}

runTests
