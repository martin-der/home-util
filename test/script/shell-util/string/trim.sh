#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../../runner.sh"


oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${src_root_dir}/resources"
}

testTrimLeft() {
	local s

	s=`mdu_trim_left "   abc"`
	assertEquals 0 $?
	assertEquals abc "$s"

	s=`mdu_trim_left "   abc  "`
	assertEquals 0 $?
	assertEquals "abc  " "$s"
}

testTrimRight() {
	local s

	s=`mdu_trim_right "abc    "`
	assertEquals 0 $?
	assertEquals abc "$s"

	s=`mdu_trim_right "  abc   "`
	assertEquals 0 $?
	assertEquals "  abc" "$s"
}

testTrim() {
	local s

	s=`mdu_trim "abc    "`
	assertEquals 0 $?
	assertEquals abc "$s"

	s=`mdu_trim "  abc"`
	assertEquals 0 $?
	assertEquals abc "$s"

	s=`mdu_trim "  abc   "`
	assertEquals 0 $?
	assertEquals abc "$s"
}

runTests
