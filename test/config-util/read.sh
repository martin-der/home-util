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
	assertEquals "Var 'FOO' has been created with correct value" "enemy" "$FOO"

	convertConfigKeyAndExportToEnvVariableIfExists "passwd" "12345" "$properties_2_var"
	assertEquals "Var name for key 'passwd' has been found" 0 $?
	assertEquals "Var 'PASSWORD' has been created with correct value" "12345" "$PASSWORD"

	convertConfigKeyAndExportToEnvVariableIfExists "baaar" "Is this a bar?" "$properties_2_var"
	assertEquals "Var name for key 'baaar' has been found" 0 $?
	assertEquals "Var 'BAR' has been created with correct value" "Is this a bar?" "$BAR"

	convertConfigKeyAndExportToEnvVariableIfExists "fiiibuuur.status" "down" "$properties_2_var"
	assertEquals "Var name for key 'fiiibuuur.status' has been found" 0 $?
	assertEquals "Var 'STATE' has been created with correct value" "down" "$STATE"
}
testExportTypedProperty() {

	local properties_2_var="foooo=FOO
passwd=PASSWORD:string
righteous=OK:boolean
fiiibuuur.status=STATE:string"

	convertConfigKeyAndExportToEnvVariableIfExists "righteous" "true" "$properties_2_var"
	assertEquals "Var name for key 'righteous' has been found" 0 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"

	convertConfigKeyAndExportToEnvVariableIfExists "righteous" "no" "$properties_2_var"
	assertEquals "Var name for key 'righteous' has been found" 0 $?
	assertEquals "Var 'OK' has been created with correct value" "0" "$OK"

	convertConfigKeyAndExportToEnvVariableIfExists "righteous" "1" "$properties_2_var"
	assertEquals "Var name for key 'righteous' has been found" 0 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"

	convertConfigKeyAndExportToEnvVariableIfExists "fiiibuuur.status" "down" "$properties_2_var"
	assertEquals "Var name for key 'fiiibuuur.status' has been found" 0 $?
	assertEquals "Var 'STATE' has been created with correct value" "down" "$STATE"
}

testFailToExportTypedProperty() {

	local properties_2_var="foooo=FOO
passwd=PASSWORD:string
righteous=OK:boolean
fiiibuuur.status=STATE:string"

	convertConfigKeyAndExportToEnvVariableIfExists "righteoussss" "troo" "$properties_2_var"
	# if var is not found => return 1
	assertEquals "Var name for key 'righteous' has been found" 1 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"

	convertConfigKeyAndExportToEnvVariableIfExists "righteous" "troo" "$properties_2_var"
	# if var couldn'd be properly converted => return 2
	assertEquals "Var name for key 'righteous' has been found" 2 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"
}



testFailToExportProperty() {
	local properties_2_var="foooo=FOO
passwd=PASSWORD
   baaar  =BAR
fiiibuuur.status=STATE"

	convertConfigKeyAndExportToEnvVariableIfExists "plain.test.password" "23456" "$properties_2_var"
	assertEquals "Var name for key 'plain.test.password' has not been found" 1 $?
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

