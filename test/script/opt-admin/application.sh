#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${test_root_dir}/resources"
}


setUp() {
	TMP_DIR=`mktemp -d`
	export MDU_OPT_DIRECTORY="$TMP_DIR"
}
tearDown() {
	rm -rf "$TMP_DIR"
}


optAdmin() {
	"${src_root_dir}/opt-admin.sh" "$@"
}

testCreateApplication() {
	optAdmin create foo-app
	assertEquals 0 $?
	assertTrue "Directory '$MDU_OPT_DIRECTORY/pkg/foo-app.d' has been created" "[ -d \"$MDU_OPT_DIRECTORY/pkg/foo-app.d\" ]"
}


testFailToInstallAlternativeWithoutSource() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin install foo-app
	assertNotSame 0 $?
}
testFailToCreateSameApplication() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin create foo-app
	assertNotSame 0 $?
}

testInstallAlternativeFromTarGz() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin install foo-app "$RESOURCES_DIR/foobix.tar.gz"
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}
testInstallNamedAlternativeFromTarGz() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin install foo-app "$RESOURCES_DIR/foobix.tar.gz" foobix-v0
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix-v0/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}

testInstallAlternativeFromZip() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin install foo-app "$RESOURCES_DIR/foobix.zip"
	assertEquals 0 $?
	output="$(grep "Known bugs" "$TMP_DIR/pkg/foo-app.d/foobix/README.md")"
	assertEquals 0 $?
	assertEquals "foobix's readme contains 'Known Bugs'" "## Known bugs" "$output"
}

testInstallAlternativeFromDirectory() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin install foo-app "$RESOURCES_DIR/foobix"
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}
testInstallNamedAlternativeFromDirectory() {
	optAdmin create foo-app
	assertEquals 0 $?
	optAdmin install foo-app "$RESOURCES_DIR/foobix" foobix-v0
	assertEquals 0 $?
	output="$("$TMP_DIR/pkg/foo-app.d/foobix-v0/bin/foobix")"
	assertEquals 0 $?
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}


runTests
