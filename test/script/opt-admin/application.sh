#!/bin/bash

pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../../.."
popd > /dev/null
test_root_dir="${root_dir}/test"


oneTimeSetUp() {
	. "${root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${test_root_dir}/resources"
}


setUp() {
	TMP_DIR=`mktemp -d`
	export MDU_OPT_DIRECTORY="$TMP_DIR"
}
tearDown() {
	rm -rf "$TMP_DIR"
}


testCreateApplication() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	assertTrue "Directory '$MDU_OPT_DIRECTORY/pkg/foo-app.d' has been created" "[ -d \"$MDU_OPT_DIRECTORY/pkg/foo-app.d\" ]"
}


testFailToInstallAlternativeWithoutSource() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh install foo-app
	assertNotSame 0 $?
}
testFailToCreateSameApplication() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh create foo-app
	assertNotSame 0 $?
}

testInstallAlternativeFromTarGz() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh install foo-app "$RESOURCES_DIR/foobix.tar.gz"
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}
testInstallNamedAlternativeFromTarGz() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh install foo-app "$RESOURCES_DIR/foobix.tar.gz" foobix-v0
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix-v0/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}

testInstallAlternativeFromZip() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh install foo-app "$RESOURCES_DIR/foobix.zip"
	assertEquals 0 $?
	output="$(grep "Known bugs" "$TMP_DIR/pkg/foo-app.d/foobix/README.md")"
	assertEquals 0 $?
	assertEquals "foobix's readme contains 'Known Bugs'" "## Known bugs" "$output"
}

testInstallAlternativeFromDirectory() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh install foo-app "$RESOURCES_DIR/foobix"
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}
testInstallNamedAlternativeFromDirectory() {
	./opt-admin.sh create foo-app
	assertEquals 0 $?
	./opt-admin.sh install foo-app "$RESOURCES_DIR/foobix" foobix-v0
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix-v0/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

