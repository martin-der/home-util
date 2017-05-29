#!/usr/bin/env bash


common_oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${test_common_resources_dir}"

	TMP_DIR=`mktemp -d` || exit 2
	trap "rm -rf '$TMP_DIR'" EXIT
	FOOBAR_PROJECT_DIR="$TMP_DIR/foobar_project"
	export MDU_BUP_DIRECTORY="$TMP_DIR/BUP"
	OUTPUT_DIRECTORY="$TMP_DIR/output"
}


common_setUp() {
	mkdir "${MDU_BUP_DIRECTORY}"
	mkdir "${OUTPUT_DIRECTORY}"
	createGitRepository
}
common_tearDown() {
	rm -rf "${MDU_BUP_DIRECTORY}"
	rm -rf "${FOOBAR_PROJECT_DIR}"
	rm -rf "${OUTPUT_DIRECTORY}"
}

createGitRepository() {
	(
		cp -r "$RESOURCES_DIR/foobar_project" "${FOOBAR_PROJECT_DIR}" || exit 5
		cd "${FOOBAR_PROJECT_DIR}" || exit 5

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

		sed -i.bak "s/onything/anything/g" "foobar"
		git add -- "foobar" || exit 5
		git commit -m "Fix another typo" >/dev/null || exit 5

		rm -f "foobar.bak"
	)
}

mkArchive() {
	"${src_root_dir}/mkGitArchive.sh" "$@"
}
count_files_in() {
	( cd "$1" && ls -1 | wc -l )
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

unzip_mute_empty_warning() {
	unzip "$1" 2>&1 | grep -v "zipfile is empty"
}