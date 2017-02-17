#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../.."
popd > /dev/null
test_root_dir="${root_dir}/test"

oneTimeSetUp() {
	. "${root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${root_dir}/resources"
}


properties="food=apple
foo=apple
animal=lion
#color=red
state=idle
age=11"

properties_2="food=apple
 foo   = apple
  animal =cow
 state   = idle   
age=11"



testFindFirstProperty() {
	local food="$(echo "$properties" | find_property "food")"
	assertEquals 0 $?
	assertEquals apple "$food"
}

testFindProperty() {
	local animal="$(echo "$properties" | find_property "animal")"
	assertEquals 0 $?
	assertEquals lion "$animal"
}

testDontFindPropertyInComment() {
	local color
	color="$(echo "$properties" | find_property "#color")"
	assertNotSame "find_property '#color'" 0 $?
	assertEquals "" "$color"
	color="$(echo "$properties" | find_property "color")"
	assertNotSame "find_property 'color'" 0 $?
	assertEquals "" "$color"
}

testFindPropertyWhitSpacesInKeys() {
	local animal="$(echo "$properties_2" | find_property "animal")"
	assertEquals 0 $?
	assertEquals cow "$animal"
}

testFailToFindProperty() {
	local animal
	animal=$(find_property "pirate" "$properties" )
	local r=$?
	echo "r=$r"
	assertNotSame "Property 'pirate' was not found" 0 $r
}




. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

