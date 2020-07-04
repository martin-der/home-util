#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	export MDU_HUMAN_MODE=0
	export MDU_NO_COLOR=1
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${test_common_resources_dir}"

	TMP_DIR=`mktemp -d` || exit 1
	cp -r "$RESOURCES_DIR/kitchen" "$TMP_DIR"
	ln -s "drawer1/spoon.sh" "$TMP_DIR/kitchen/ladle.sh"
	ln -s "drawer1/fruits-basket.sh" "$TMP_DIR/kitchen/fruits-basket.sh"
	cp -r "$RESOURCES_DIR/journey.sh" "$TMP_DIR"
}
oneTimeTearDown() {
	rm -rf "$TMP_DIR"
}
setUp() {
	:
}
tearDown() {
	:
}

testSimpleInclude() {
	local result expected
	expected="Some black grape in the kitchen\
"
	export MDU_SOURCE_OPTIONS=n

	result="$(load_source "$TMP_DIR/kitchen/grape.sh")"
	assertEquals 0 $?
	assertEquals "$expected" "$result"

	result="$(load_source "$TMP_DIR/kitchen/grape" "sh")"
	assertEquals 0 $?
	assertEquals "$expected" "$result"
}


testRecursiveInclude() {
	local result expected
	expected="A spoon in the drawer 1
A soup in the drawer 2
A spoon in the drawer 1
A yogurt in the drawer 2
A knife in the kitchen
A yellow apple in the drawer 1
A plate in the kitchen
That was a nice meal"
	export MDU_SOURCE_OPTIONS=n
	result="$(load_source "$TMP_DIR/kitchen/meal" sh)"
	assertEquals 0 $?
	assertEquals "$expected" "$result"
}

testIncludeScriptNotFound() {
	local result expected
	expected="[ERROR] Failed to source '$TMP_DIR/what' : not found"
	result="$(load_source "$TMP_DIR/what" sh 2>&1)"
	assertEquals 254 $?
	assertEquals "$expected" "$result"
}

testInnerIncludeScriptNotFound() {
	local result expected
	expected="[ERROR] Failed to source 'holy-grail' : not found"
	result="$(load_source "$TMP_DIR/journey" sh 2>&1)"
	assertEquals 1 $?
	assertEquals "$expected" "$result"
}

testRecursiveIncludeOnce() {
	local result expected
	expected="A spoon in the drawer 1
A soup in the drawer 2
A yogurt in the drawer 2
A knife in the kitchen
A yellow apple in the drawer 1
A plate in the kitchen
That was a nice meal"
	export MDU_SOURCE_OPTIONS=1
	result="$(load_source_once "$TMP_DIR/kitchen/meal" sh)"
	assertEquals 0 $?
	assertEquals "$expected" "$result"
}

testIncludeLinkedFirstThenRealScript() {
	local result expected
	expected="A yellow apple in the drawer 1
An orange in the drawer 1
A fruit basket in the drawer 1"
	result="$(load_source "$TMP_DIR/kitchen/fruits-basket" sh)"
	assertEquals 0 $?
	assertEquals "$expected" "$result"
}


runTests
