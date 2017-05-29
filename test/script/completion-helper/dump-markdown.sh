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

\`smart_dog.sh <global_options> fetch <options> <what> [to]\` [detail](#Usage 1)

\`smart_dog.sh <global_options> hold <what>\` [detail](#Usage 2)

\`smart_dog.sh <global_options> bark <sound>\` [detail](#Usage 3)

\`smart_dog.sh <global_options> sleep <duration>\` [detail](#Usage 4)

\`smart_dog.sh <global_options> smell\` [detail](#Usage 5)

\`smart_dog.sh <global_options> call <name>\` [detail](#Usage 6)


## Description

This application helps your to interact with you dog.

### Usage 1

\`smart_dog.sh <global_options> fetch <options> <what> [to]\`
##### Options

### Usage 2

\`smart_dog.sh <global_options> hold <what>\`

### Usage 3

\`smart_dog.sh <global_options> bark <sound>\`

### Usage 4

\`smart_dog.sh <global_options> sleep <duration>\`

### Usage 5

\`smart_dog.sh <global_options> smell\`

### Usage 6

\`smart_dog.sh <global_options> call <name>\`"

	markdown_text="$("${test_common_resources_dir}/smart_dog.sh" help --dump-markdown)"
	assertLastCommandSucceeded
	assertEquals "$expected_markdown_text" "$markdown_text"

	echo "$expected_markdown_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog-expected.md"
	echo "$markdown_text" > "${MDU_SHELLTEST_TEST_RESULTS_DIRECTORY}/smartdog.md"
}

runTests
