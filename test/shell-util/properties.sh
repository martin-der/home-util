#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
test_root_dir="$(pwd -P)/.."
popd > /dev/null


oneTimeSetUp() {
	. "${test_root_dir}/../shell-util.sh" || exit 1
}

properties="food=apple
foo=apple
animal=lion
state=idle
age=11"

properties_2="food=apple
foo=apple
animal=lion
#color=red
state=idle
age=11"


testFindFirstProperty() {
	local animal="$(echo "$properties" | find_property "animal")"
	assertEquals $? 0
	assertEquals lion "$animal"
}

testFindProperty() {
	local food="$(echo "$properties" | find_property "food")"
	assertEquals $? 0
	assertEquals apple "$food"
}

testDontFindPropertyInComment() {
	local color="$(echo "$properties" | find_property "#color")"
	assertNotEquals $? 0
	assertEquals "" "$color"
	color="$(echo "$properties" | find_property "color")"
	assertNotEquals $? 0
	assertEquals "" "$color"
}



. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"


