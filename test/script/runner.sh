#!/bin/bash

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
root_dir="$(pwd -P)/../.."
popd > /dev/null
src_root_dir="${root_dir}/src"
test_root_dir="${root_dir}/test"


runTests() {
	. "${test_root_dir}/shunit2-2.0.3/src/shell/shunit2" || exit 4
	[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0
}

assertLastCommandFailed() {
	local last_result
	last_result=$?
	[ $# -gt 1 ] && {
		assertNotSame "$1" "$2" $last_result
		return $?
	} || {
		assertNotSame "Assert Failed" 0 $last_result
		return $?
	}
}
assertLastCommandSucceeded() {
	local last_result
	last_result=$?
	[ $# -gt 0 ] && {
		assertEquals "$1" 0 $last_result
		return $?
	} || {
		assertEquals 0 $last_result
		return $?
	}
}
