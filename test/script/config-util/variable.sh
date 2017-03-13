#!/bin/bash

pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../../.."
popd > /dev/null
test_root_dir="${root_dir}/test"


oneTimeSetUp() {
	. "${root_dir}/config-util.sh" || exit 1
	RESOURCES_DIR="${test_root_dir}/resources"
}


setUp() {
	:
}
tearDown() {
	:
}



testPrintVariable() {
	local foobar text

	foobar="try again"
	text=$(printVariable foobar)
	assertEquals "(+)foobar:'try again'" "$text"
	foobar=" try    one more    time    "
	text=$(printVariable foobar)
	assertEquals "(+)foobar:' try    one more    time    '" "$text"
}
testPrintUndefinedVariable() {
	local text
	text=$(printVariable foobar)
	assertEquals "(-)foobar" "$text"
}

testConvertBoolean() {
	local converted
	converted=$(convertVariable boolean 1)
	assertEquals 0 $?
	assertEquals 1 "$converted"
	converted=$(convertVariable boolean "true")
	assertEquals 0 $?
	assertEquals 1 "$converted"
	converted=$(convertVariable boolean "yes")
	assertEquals 0 $?
	assertEquals 1 "$converted"

	converted=$(convertVariable boolean 0)
	assertEquals 0 $?
	assertEquals 0 "$converted"
	converted=$(convertVariable boolean "false")
	assertEquals 0 $?
	assertEquals 0 "$converted"
	converted=$(convertVariable boolean "no")
	assertEquals 0 $?
	assertEquals 0 "$converted"

	converted=$(convertVariable boolean "yep")
	assertNotSame 0 $?
	assertEquals "" "$converted" 
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

