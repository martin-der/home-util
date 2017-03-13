#!/bin/bash

pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../../.."
popd > /dev/null
test_root_dir="${root_dir}/test"



testIdentifyCapableScript() {
	local response
	response="$(bash "${root_dir}/completion-helper.sh" "${test_root_dir}/resources/i_can_complete.sh")"
	assertEquals 0 $?
	assertEquals "Capable" "$response"
}

testIdentifyNotCapableScriptBecauseNotABashScript() {
	local response
	response="$(bash "${root_dir}/completion-helper.sh" "${test_root_dir}/resources/i_cannot_complete_NOT_BASH.sh")"
	assertNotSame 0 $?
	assertEquals "Not Capable" "$response"
}

testIdentifyNotCapableScriptBecauseNotTagged() {
	local response
	response="$(bash "${root_dir}/completion-helper.sh" "${test_root_dir}/resources/i_cannot_complete_NOT_TAGGED.sh")"
	assertNotSame 0 $?
	assertEquals "Not Capable" "$response"
}

testIdentifyNotCapableNotExistingScript() {
	local response
	response="$(bash "${root_dir}/completion-helper.sh" "${test_root_dir}/resources/no_such_file.sh")"
	assertNotSame 0 $?
	assertEquals "" "$response"
}
testIdentifyNotCapableNotReadableScript() {
	# TODO : move not_readable_file in temp directory so we don't have to modify a tracked file
	chmod u-r "${test_root_dir}/resources/not_readable_file.sh"
	local response
	response="$(bash "${root_dir}/completion-helper.sh" "${test_root_dir}/resources/not_readable_file.sh")"
	assertNotSame 0 $?
	assertEquals "" "$response"
	chmod u+r "${test_root_dir}/resources/not_readable_file.sh"
}





. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

