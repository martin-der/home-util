#!/usr/bin/env bash

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

test_ZipModifiedFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/foobar\" ]"
	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}
test_ZipMoreModifiedFiles() {
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
test_ZipNewFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n )
	__assertLastCommandSucceeded $? "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	__assertLastCommandSucceeded $? "Unzip archive"
	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/foobar_project/newfile.txt"
	assertTrue "greeting.txt was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/greeting.txt\" ]"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/foobar\" ]"
	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}
test_ZipNewAndModifiedFiles() {
	modifyProject || exit 2
	modifyProject2 || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -n )
	__assertLastCommandSucceeded $? "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	__assertLastCommandSucceeded $? "Unzip archive"
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar_project/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/foobar_project/newfile.txt"
	assertEquals "3 files in output" 3 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}

test_FailCreatingEmptyZipWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m 2>/dev/null )
	__assertLastCommandFailed $? "Make archive" ""
}
test_CreatingEmptyZipWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -e )
	__assertLastCommandSucceeded $? "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	__assertLastCommandSucceeded $? "Unzip archive"
}
zztest_FailCreatingEmptyZipWithNewFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n 2>/dev/null )
	__assertLastCommandFailed "Make archive" ""
}
test_testCreatingEmptyZipWithNewFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -e )
	__assertLastCommandSucceeded $? "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	__assertLastCommandSucceeded $? "Unzip archive"
}


#testZipNoPrefixModifiedFiles() {
#	modifyProject || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" )
#	__assertLastCommandSucceeded $? "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	__assertLastCommandSucceeded $? "Unzip archive"
#	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
#	assertTrue "foobar was not in the archive" "[ ! -e \"${OUTPUT_DIRECTORY}/foobar\" ]"
#	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#testZipNoPrefixMoreModifiedFiles() {
#	modifyProject || exit 2
#	modifyProject2 || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" )
#	__assertLastCommandSucceeded $? "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	__assertLastCommandSucceeded $? "Unzip archive"
#	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
#	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
#	assertEquals "2 files in output" 2 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#testZipNoPrefixNewFiles() {
#	modifyProject || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -p "" )
#	__assertLastCommandSucceeded $? "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	__assertLastCommandSucceeded $? "Unzip archive"
#	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/newfile.txt"
#	assertTrue "greeting.txt was not in the archive" "[ ! -e \"${OUTPUT_DIRECTORY}/greeting.txt\" ]"
#	assertTrue "foobar was not in the archive" "[ ! -e \"${OUTPUT_DIRECTORY}/foobar\" ]"
#	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#testZipNoPrefixNewAndModifiedFiles() {
#	modifyProject || exit 2
#	modifyProject2 || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -n -p "" )
#	__assertLastCommandSucceeded $? "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	__assertLastCommandSucceeded $? "Unzip archive"
#	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
#	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
#	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/newfile.txt"
#	assertEquals "3 files in output" 3 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#
__testFailCreatingEmptyZipNoPrefixWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" 2>/dev/null )
	__assertLastCommandFailed $? "Make archive" ""
}
#testCreatingEmptyZipNoPrefixWithModifiedFiles() {
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" -e )
#	__assertLastCommandSucceeded $? "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	__assertLastCommandSucceeded $? "Unzip archive"
#}
#testFailCreatingEmptyZipNoPrefixWithNewFiles() {
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -p "" 2>/dev/null )
#	assertLastCommandFailed "Make archive" ""
#}
#testCreatingEmptyZipNoPrefixWithNewFiles() {
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -p "" -e )
#	__assertLastCommandSucceeded $? "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	__assertLastCommandSucceeded $? "Unzip archive"
#}


runTests
