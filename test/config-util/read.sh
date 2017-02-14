#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../.."
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


testExportProperty() {

	local properties_2_var="foooo=FOO
passwd=PASSWORD
   baaar  =BAR
fiiibuuur.status=STATE"

	convertConfigKeyAndExportToEnvVariableIfExists "foooo" "enemy" "$properties_2_var"
	assertEquals "Var name for key 'foooo' has been found" 0 $?
	assertEquals "Var 'FOO' has been created with correct value" "$FOO" "enemy" 

	convertConfigKeyAndExportToEnvVariableIfExists "passwd" "12345" "$properties_2_var"
	assertEquals "Var name for key 'passwd' has been found" 0 $?
	assertEquals "Var 'PASSWORD' has been created with correct value" "$PASSWORD" "12345" 

	convertConfigKeyAndExportToEnvVariableIfExists "baaar" "Is this a bar?" "$properties_2_var"
	assertEquals "Var name for key 'baaar' has been found" 0 $?
	assertEquals "Var 'BAR' has been created with correct value" "$BAR" "Is this a bar?" 

	convertConfigKeyAndExportToEnvVariableIfExists "fiiibuuur.status" "down" "$properties_2_var"
	assertEquals "Var name for key 'fiiibuuur.status' has been found" 0 $?
	assertEquals "Var 'STATE' has been created with correct value" "$STATE" "down" 

}


testFailToExportProperty() {
	local properties_2_var="foooo=FOO
passwd=PASSWORD
   baaar  =BAR
fiiibuuur.status=STATE"

	convertConfigKeyAndExportToEnvVariableIfExists "plain.test.password" "23456" "$properties_2_var"
	assertNotSame "Var name for key 'plain.test.password' has not been found" 0 $?
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

