#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	. "${src_root_dir}/config-util.sh" || exit 1
	RESOURCES_DIR="${test_common_resources_dir}"
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
fiiibuuur.status=STATE
"

	convertConfigKeyToVariable "foooo" "enemy" "$properties_2_var"
	assertEquals "Var name for key 'foooo' has been found" 0 $?
	assertEquals "Var 'FOO' has been created with correct value" "enemy" "$FOO"

	convertConfigKeyToVariable "passwd" "12345" "$properties_2_var"
	assertEquals "Var name for key 'passwd' has been found" 0 $?
	assertEquals "Var 'PASSWORD' has been created with correct value" "12345" "$PASSWORD"

	convertConfigKeyToVariable "baaar" "Is this a bar?" "$properties_2_var"
	assertEquals "Var name for key 'baaar' has been found" 0 $?
	assertEquals "Var 'BAR' has been created with correct value" "Is this a bar?" "$BAR"

	convertConfigKeyToVariable "fiiibuuur.status" "down" "$properties_2_var"
	assertEquals "Var name for key 'fiiibuuur.status' has been found" 0 $?
	assertEquals "Var 'STATE' has been created with correct value" "down" "$STATE"
}
disabled_testExportTypedProperty() {

	local properties_2_var="foooo=FOO
passwd=PASSWORD:string
righteous=OK:boolean
fiiibuuur.status=STATE:string"

	convertConfigKeyToVariable "righteous" "true" "$properties_2_var"
	assertEquals "Var name for key 'righteous' has been found" 0 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"

	convertConfigKeyToVariable "righteous" "no" "$properties_2_var"
	assertEquals "Var name for key 'righteous' has been found" 0 $?
	assertEquals "Var 'OK' has been created with correct value" "0" "$OK"

	convertConfigKeyToVariable "righteous" "1" "$properties_2_var"
	assertEquals "Var name for key 'righteous' has been found" 0 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"

	convertConfigKeyToVariable "fiiibuuur.status" "down" "$properties_2_var"
	assertEquals "Var name for key 'fiiibuuur.status' has been found" 0 $?
	assertEquals "Var 'STATE' has been created with correct value" "down" "$STATE"
}

disabled_testFailToExportTypedProperty() {

	local properties_2_var="foooo=FOO
passwd=PASSWORD:string
righteous=OK:boolean
fiiibuuur.status=STATE:string"

	convertConfigKeyToVariable "righteoussss" "troo" "$properties_2_var" 2>/dev/null
	# if var is not found => return 1
	assertEquals "Var name for key 'righteous' has been found" 1 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"

	convertConfigKeyToVariable "righteous" "troo" "$properties_2_var" 2>/dev/null
	# if var couldn'd be properly converted => return 2
	assertEquals "Var name for key 'righteous' has been found" 2 $?
	assertEquals "Var 'OK' has been created with correct value" "1" "$OK"
}



testFailToExportProperty() {
	local properties_2_var="foooo=FOO
passwd=PASSWORD
   baaar  =BAR
fiiibuuur.status=STATE"

	convertConfigKeyToVariable "plain.test.password" "23456" "$properties_2_var"
	assertEquals "Var name for key 'plain.test.password' has not been found" 1 $?
}


runTests
