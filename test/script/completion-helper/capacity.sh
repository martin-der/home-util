#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


testIdentifyCapableScript() {
	local response
	response="$(bash "${src_root_dir}/completion-helper.sh" "${test_common_resources_dir}/i_can_complete.sh")"
	assertEquals 0 $?
	assertEquals "Capable" "$response"
}

testIdentifyNotCapableScriptBecauseNotABashScript() {
	local response
	response="$(bash "${src_root_dir}/completion-helper.sh" "${test_common_resources_dir}/i_cannot_complete_NOT_BASH.sh")"
	assertNotSame 0 $?
	assertEquals "Not Capable" "$response"
}

testIdentifyNotCapableScriptBecauseNotTagged() {
	local response
	response="$(bash "${src_root_dir}/completion-helper.sh" "${test_common_resources_dir}/i_cannot_complete_NOT_TAGGED.sh")"
	assertNotSame 0 $?
	assertEquals "Not Capable" "$response"
}

testIdentifyNotCapableNotExistingScript() {
	local response
	response="$(bash "${src_root_dir}/completion-helper.sh" "${test_common_resources_dir}/no_such_file.sh" 2>/dev/null)"
	assertNotSame 0 $?
	assertEquals "" "$response"
}
testIdentifyNotCapableNotReadableScript() {
	# TODO : move not_readable_file in temp directory so we don't have to modify a tracked file
	chmod u-r "${test_common_resources_dir}/not_readable_file.sh"
	local response
	response="$(bash "${src_root_dir}/completion-helper.sh" "${test_common_resources_dir}/not_readable_file.sh" 2>/dev/null)"
	assertNotSame 0 $?
	assertEquals "" "$response"
	chmod u+r "${test_common_resources_dir}/not_readable_file.sh"
}



runTests
