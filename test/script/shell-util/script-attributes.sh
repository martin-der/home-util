#!/usr/bin/env bash

set -e

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

ERROR_DOES_NO_HAVE_ATTRIBUTE=3

oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${test_common_resources_dir}"
}


testAttributeFoobarLeft() {
	local result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_1.sh" "foobar-left"
	result=$?
	assertEquals "'script 1' has attribute 'foobar-left'" 0 $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_2.sh" "foobar-left"
	result=$?
	assertEquals "'script 2' does not have attribute 'foobar-left'" $ERROR_DOES_NO_HAVE_ATTRIBUTE $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_3.sh" "foobar-left"
	result=$?
	assertEquals "'script 3' has attribute 'foobar-left'" 0 $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_4.sh" "foobar-left"
	result=$?
	assertEquals "'script 4' has attribute 'foobar-left'" 0 $result
}

testAttributeFoobarRight() {
	local result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_1.sh" "foobar-right"
	result=$?
	assertEquals "'script 1' has attribute 'foobar-right'" 0 $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_2.sh" "foobar-right"
	result=$?
	assertEquals "'script 2' does not have attribute 'foobar-right'" 0 $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_3.sh" "foobar-right"
	result=$?
	assertEquals "'script 3' has attribute 'foobar-right'" $ERROR_DOES_NO_HAVE_ATTRIBUTE $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_4.sh" "foobar-right"
	result=$?
	assertEquals "'script 4' has attribute 'foobar-right'" 0 $result
}

testAttributeFoobarMiddle() {
	local result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_1.sh" "foobar-middle"
	result=$?
	assertEquals "'script 1' has attribute 'foobar-middle'" $ERROR_DOES_NO_HAVE_ATTRIBUTE $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_2.sh" "foobar-middle"
	result=$?
	assertEquals "'script 2' does not have attribute 'foobar-middle'" 0 $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_3.sh" "foobar-middle"
	result=$?
	assertEquals "'script 3' has attribute 'foobar-middle'" $ERROR_DOES_NO_HAVE_ATTRIBUTE $result

	mdu_script_has_attribute "$RESOURCES_DIR/i_can_haz_a_foobar_4.sh" "foobar-middle"
	result=$?
	assertEquals "'script 4' has attribute 'foobar-middle'" 0 $result
}



runTests
