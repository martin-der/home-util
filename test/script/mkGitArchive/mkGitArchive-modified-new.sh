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

modifyProject() {
	(
		cd "${FOOBAR_PROJECT_DIR}" || return 2
		(
			echo "I hope you're fine." >> "greeting.txt"
			echo "abcdef" >> "newfile.txt"
		) || return 2
	)
}

modifyProject2() {
	(
		cd "${FOOBAR_PROJECT_DIR}" || return 2
		(
			echo "That thing" >> "foobar"
		) || return 2
	)
}

# tar -tzf file.tar.gz | wc -l

testZipModifiedFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/foobar\" ]"
	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}
testZipMoreModifiedFiles() {
	modifyProject || exit 2
	modifyProject2 || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar_project/foobar"
	assertEquals "2 files in output" 2 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}
testZipNewFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/foobar_project/newfile.txt"
	assertTrue "greeting.txt was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/greeting.txt\" ]"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/foobar\" ]"
	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}
testZipNewAndModifiedFiles() {
	modifyProject || exit 2
	modifyProject2 || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -n )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar_project/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/foobar_project/newfile.txt"
	assertEquals "3 files in output" 3 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}

testFailCreatingEmptyZipWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m 2>/dev/null )
	assertLastCommandFailed "Make archive" ""
}
testCreatingEmptyZipWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -e )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
}
testFailCreatingEmptyZipWithNewFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n 2>/dev/null )
	assertLastCommandFailed "Make archive" ""
}
testCreatingEmptyZipWithNewFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -e )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
}


runTests
