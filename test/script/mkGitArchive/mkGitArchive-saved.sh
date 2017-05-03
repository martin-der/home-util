#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh" || exit 4
source "$(dirname "${BASH_SOURCE[0]}")/common.sh" || exit 4


oneTimeSetUp() {
	common_oneTimeSetUp
}

setUp() {
	common_setUp
}
tearDown() {
	common_tearDown
}


testZipWithGitContent() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -g -a zip )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null ; )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar_project/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertSameFiles "README.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/README.txt" "${OUTPUT_DIRECTORY}/foobar_project/README.txt"
	assertTrue "Git data directory has been unzipped" "[ -d \"$OUTPUT_DIRECTORY/foobar_project/.git\" ]"
	assertEquals "3 files in output" 3 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project/")"
}

testCustomBackupDirectory() {
	mkdir "${MDU_BUP_DIRECTORY}/warehouse"
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -B "${MDU_BUP_DIRECTORY}/warehouse" )
	assertLastCommandSucceeded "Make archive"
	assertEquals "2 files in backup dir ( the zip and the tar.gz )" 2 "$(count_files_in "${MDU_BUP_DIRECTORY}/warehouse")"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/warehouse/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar_project/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertSameFiles "README.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/README.txt" "${OUTPUT_DIRECTORY}/foobar_project/README.txt"
	#assertTrue "Git data directory has been unzipped" "[ -d \"$OUTPUT_DIRECTORY/foobar_project/.git\" ]"
	assertEquals "1 files in parent backup dir" 1 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}


runTests
