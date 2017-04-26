#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"


oneTimeSetUp() {
	common_oneTimeSetUp
}

setUp() {
	common_setUp
}
tearDown() {
	common_tearDown
}


testSimpleZipWithGitContent() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
	assertSameFiles "README.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/README.txt" "${OUTPUT_DIRECTORY}/README.txt"
	assertTrue "Git data directory has been unzipped" "[ -d \"$OUTPUT_DIRECTORY/.git\" ]"
}


runTests
