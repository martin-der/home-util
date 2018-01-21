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

ZZtestZipModifiedFiles() {
	modifyProject || exit 2
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/foobar_project/greeting.txt"
	assertTrue "foobar was not in the archive" "[ ! -e \"$OUTPUT_DIRECTORY/foobar_project/foobar\" ]"
	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}/foobar_project")"
}
ZZtestZipMoreModifiedFiles() {
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
ZZtestZipNewFiles() {
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
ZZtestZipNewAndModifiedFiles() {
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

ZZtestFailCreatingEmptyZipWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m 2>/dev/null )
	assertLastCommandFailed "Make archive" ""
}
ZZtestCreatingEmptyZipWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -e )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
}
ZZtestFailCreatingEmptyZipWithNewFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n 2>/dev/null )
	assertLastCommandFailed "Make archive" ""
}
ZZtestCreatingEmptyZipWithNewFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -e )
	assertLastCommandSucceeded "Make archive"
	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	assertLastCommandSucceeded "Unzip archive"
}


#testZipNoPrefixModifiedFiles() {
#	modifyProject || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" )
#	assertLastCommandSucceeded "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	assertLastCommandSucceeded "Unzip archive"
#	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
#	assertTrue "foobar was not in the archive" "[ ! -e \"${OUTPUT_DIRECTORY}/foobar\" ]"
#	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#testZipNoPrefixMoreModifiedFiles() {
#	modifyProject || exit 2
#	modifyProject2 || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" )
#	assertLastCommandSucceeded "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	assertLastCommandSucceeded "Unzip archive"
#	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
#	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
#	assertEquals "2 files in output" 2 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#testZipNoPrefixNewFiles() {
#	modifyProject || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -p "" )
#	assertLastCommandSucceeded "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	assertLastCommandSucceeded "Unzip archive"
#	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/newfile.txt"
#	assertTrue "greeting.txt was not in the archive" "[ ! -e \"${OUTPUT_DIRECTORY}/greeting.txt\" ]"
#	assertTrue "foobar was not in the archive" "[ ! -e \"${OUTPUT_DIRECTORY}/foobar\" ]"
#	assertEquals "1 files in output" 1 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#testZipNoPrefixNewAndModifiedFiles() {
#	modifyProject || exit 2
#	modifyProject2 || exit 2
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -n -p "" )
#	assertLastCommandSucceeded "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	assertLastCommandSucceeded "Unzip archive"
#	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
#	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
#	assertSameFiles "newfile.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/newfile.txt" "${OUTPUT_DIRECTORY}/newfile.txt"
#	assertEquals "3 files in output" 3 "$(count_files_in "${OUTPUT_DIRECTORY}")"
#}
#
testFailCreatingEmptyZipNoPrefixWithModifiedFiles() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" 2>/dev/null )
	assertLastCommandFailed "Make archive" ""
}
#testCreatingEmptyZipNoPrefixWithModifiedFiles() {
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -p "" -e )
#	assertLastCommandSucceeded "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	assertLastCommandSucceeded "Unzip archive"
#}
#testFailCreatingEmptyZipNoPrefixWithNewFiles() {
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -p "" 2>/dev/null )
#	assertLastCommandFailed "Make archive" ""
#}
#testCreatingEmptyZipNoPrefixWithNewFiles() {
#	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -n -p "" -e )
#	assertLastCommandSucceeded "Make archive"
#	( cd "${OUTPUT_DIRECTORY}" && unzip_mute_empty_warning "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
#	assertLastCommandSucceeded "Unzip archive"
#}


runTests
