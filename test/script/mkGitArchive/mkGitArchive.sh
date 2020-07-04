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


test_DefaultArchivesPresence() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive )
	__assertLastCommandSucceeded $? "Make archive"
	assertEquals "2 files in backup directory" 2 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}

test_ArchivesPresenceSourceOnly() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -k )
	__assertLastCommandSucceeded $? "Make archive"
	assertEquals "1 file in backup directory" 1 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}
test_ArchivesPresenceSourceWithGit() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -g )
	__assertLastCommandSucceeded $? "Make archive"
	assertEquals "1 file in backup directory" 1 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}
test_ArchivesPresenceSourceOnlyAndSourceWithGit() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -k -g )
	__assertLastCommandSucceeded $? "Make archive"
	assertEquals "2 files in backup directory" 2 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}

test_ArchivesPresenceAll() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -k -g -m -n -e )
	__assertLastCommandSucceeded $? "Make archive"
	assertEquals "3 files in backup directory" 3 "$(count_files_in "${MDU_BUP_DIRECTORY}")"
}


runTests
