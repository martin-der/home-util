#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	export MDU_LOG_LEVEL=debug
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${test_root_dir}/resources"

	TMP_DIR=`mktemp -d` || exit 2
	trap "rm -rf '$TMP_DIR'" EXIT
	FOOBAR_PROJECT_DIR="$TMP_DIR/foobar"
	export MDU_BUP_DIRECTORY="$TMP_DIR/BUP"
	OUTPUT_DIRECTORY="$TMP_DIR/output"
}


setUp() {
	mkdir "${MDU_BUP_DIRECTORY}"
	mkdir "${FOOBAR_PROJECT_DIR}"
	mkdir "${OUTPUT_DIRECTORY}"
	createGitRepository
}
tearDown() {
	rm -rf "${MDU_BUP_DIRECTORY}"
	rm -rf "${FOOBAR_PROJECT_DIR}"
}

createGitRepository() {
	(
		cd "${FOOBAR_PROJECT_DIR}" || return 5

		(
			echo "same thing"
			echo "samething else"
			echo "nathing"
		) > "foobar"

		(
			echo "Hello, world"
			echo "how are you doing?"
		) > "greeting.txt"

		(
			echo "Type 'cat greeting.txt'"
			echo "to see"
			echo "a clever text"
		) > "README.txt"

		git init >/dev/null || exit 5
		git config user.email "bot@test.org"
		git config --global user.name "Bot"

		git checkout -q -b develop >/dev/null || exit 5
		git add -- "greeting.txt" "foobar" || exit 5
		git commit -m "Init repo" >/dev/null || exit 5

		git add -- "README.txt" || exit 5
		git commit -m "Some doc" >/dev/null || exit 5

		sed -i.bak "s/a/o/g" "foobar"
		git add -- "foobar" || exit 5
		git commit -m "Fix typos" >/dev/null || exit 5
	)
}

mkArchive() {
	"${src_root_dir}/mkGitArchive.sh" "$@"
}

sameFiles() {
	[ "x$(cat "$1")" = "x$(cat "$2")" ] && return 0
	return 1
}
assertSameFiles() {
	[ $# -gt 2 ] && {
		sameFiles "$2" "$3"
		assertEquals "$1" 0 $?
		return $?
	} || {
		sameFiles "$1" "$2"
		assertEquals 0 $?
		return $?
	}
}


testSimpleZipWithGitContent() {
	( cd "${FOOBAR_PROJECT_DIR}" && mkArchive )
	assertEquals "make archive" 0 $?
	( cd "${OUTPUT_DIRECTORY}" && unzip "$MDU_BUP_DIRECTORY/foobar-*.zip" >/dev/null )
	assertEquals "unzip archive" 0 $?
	assertSameFiles "foobar has been unzipped" "${FOOBAR_PROJECT_DIR}/foobar" "${OUTPUT_DIRECTORY}/foobar"
	assertSameFiles "greeting.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/greeting.txt" "${OUTPUT_DIRECTORY}/greeting.txt"
	assertSameFiles "README.txt has been unzipped" "${FOOBAR_PROJECT_DIR}/README.txt" "${OUTPUT_DIRECTORY}/README.txt"
	assertTrue "Git data directory has been unzipped" "[ -d \"$OUTPUT_DIRECTORY/.git\" ]"
}


runTests
