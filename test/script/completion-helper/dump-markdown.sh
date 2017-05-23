#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	mkTestResultsDir
}

testDumpMarkdown() {
	local markdown_text expected_markdown_text

	expected_markdown_text="smart_dog.sh
============

## Summary

Dog interaction for newbies

## Synopsis

`smart_dog.sh <global_options> fetch <options> what...`

`smart_dog.sh <global_options> bark sound...`

`smart_dog.sh <global_options> sleep duration...`

`smart_dog.sh <global_options> smell`

`smart_dog.sh <global_options> call name...`


## Description

This application helps you to interact with you dog.

fetch what...

bark sound...

sleep duration...

smell

call name..."

	markdown_text="$("${test_root_dir}/resources/smart_dog.sh" help --dump-markdown)"
	assertLastCommandSucceeded
	assertEquals "$expected_markdown_text" "$markdown_text"

	echo "$markdown_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.md"
}

runTests
