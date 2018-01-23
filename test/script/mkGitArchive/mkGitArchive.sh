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


testDefaultArchivesPresence() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive )
	assertLastCommandSucceeded "Make archive"
	assertEquals "2 files in backup directory" 2 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}

testArchivesPresenceSourceOnly() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -k )
	assertLastCommandSucceeded "Make archive"
	assertEquals "1 file in backup directory" 1 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}
testArchivesPresenceSourceWithGit() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -g )
	assertLastCommandSucceeded "Make archive"
	assertEquals "1 file in backup directory" 1 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}
testArchivesPresenceSourceOnlyAndSourceWithGit() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -k -g )
	assertLastCommandSucceeded "Make archive"
	assertEquals "2 files in backup directory" 2 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}

testArchivesPresenceAll() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -k -g -m -n -e )
	assertLastCommandSucceeded "Make archive"
	assertEquals "3 files in backup directory" 3 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}


runTests
