#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"


oneTimeSetUp() {
	common_oneTimeSetUp
	export MDU_LOG_LEVEL=debug
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

testSimpleZipModifiedFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar\" ]"

}
testSimpleZipMoreModifiedFiles() {
	modifyProject || exit 2
	modifyProject2 || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
}
testSimpleZipNewFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/newfile.txt"
	assertTrue "greeting.txt was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/greeting.txt\" ]"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar\" ]"
}
testSimpleZipNewAndModifiedFiles() {
	modifyProject || exit 2
	modifyProject2 || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -n )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/newfile.txt"
}

ZZtestSimpleEmpyZipModifiedFiles() {
	:
}


runTests
