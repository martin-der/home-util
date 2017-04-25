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



testSimpleZipNewAndModifiedFiles() {
	(
		cd "${FOOBAR_PROJECT_DIR}" || exit 2
		(
			echo "I hope you're fine." >> "greeting.txt"
			echo "abcdef" >> "newfile.txt"
			#git add -- "greeting.txt"
		) || exit 2
	)
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive -m -n )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar_project-*.zip" >/dev/null )
	ls -l "${OUTPUT_DIRECTORY}"
	assertEquals "unzip archive" 0 $?
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
}


runTests
