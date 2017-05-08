#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	. "${src_root_dir}/config-util.sh" || exit 1
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

	converted=$(convertVariable boolean "yep" 2>/dev/null)
	assertNotSame 0 $?
	assertEquals "" "$converted" 
}


runTests
