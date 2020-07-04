#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${src_root_dir}/resources"
}


properties="food=apple
foo=apple
animal=lion
#color=red
state=idle
age=11
captain.name=rackam"

properties_2="food=apple
 foo   = apple
  animal =cow
 state   = idle   
age=11
   captain.name =   rackam"



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
testFindPropertyWithDot() {
	local name="$(echo "$properties" | find_property "captain.name")"
	assertEquals 0 $?
	assertEquals rackam "$name"
}

testDoNotFindPropertyInComment() {
	local color
	color="$(echo "$properties" | find_property "#color")"
	assertNotSame "find_property '#color'" 0 $?
	assertEquals "" "$color"
	color="$(echo "$properties" | find_property "color")"
	assertNotSame "find_property 'color'" 0 $?
	assertEquals "" "$color"
}

testFindPropertyWhitSpaces() {
	local animal="$(echo "$properties_2" | find_property "animal")"
	assertEquals 0 $?
	assertEquals cow "$animal"

	local name="$(echo "$properties_2" | find_property "captain.name")"
	assertEquals 0 $?
	assertEquals rackam "$name"

	local state="$(echo "$properties_2" | find_property "state")"
	assertEquals 0 $?
	assertEquals idle "$state"

}

testFailToFindProperty() {
	local animal
	animal=$(find_property "pirate" "$properties" )
	local r=$?
	assertNotSame "Property 'pirate' was not found" 0 $r
}



runTests
