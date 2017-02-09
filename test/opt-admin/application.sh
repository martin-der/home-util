#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
test_root_dir="$(pwd -P)/.."
popd > /dev/null


oneTimeSetUp() {
	. "${test_root_dir}/../shell-util.sh" || exit 1
	export MDU_LOG_LEVEL=info
	RESOURCES_DIR="."
}

setUp() {
	TMP_DIR=`mktemp -d`
	export MDU_OPT_DIRECTORY="$TMP_DIR"
}
tearDown() {
	rm -rf "$TMP_DIR"
}




testCreateApplication() {
	opt-admin create foo-app
	assertEquals $? 0
	assertTrue "Directory '$MDU_OPT_DIRECTORY/foo-app.d' has been created" "[ -d \"$MDU_OPT_DIRECTORY/foo-app.d\" ]"
}


testFailToInstallAlternativeWithoutSource() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin install foo-app
	assertNotSame $? 0
}
testFailToInstallSameAlternative() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin create foo-app
	assertNotSame $? 0
}

testInstallAlternativeFromDirectory() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin install foo-app "$RESOURCES_DIR/test/resources/foobix"
	assertEquals $? 0
	output="$(grep "Known bugs" "$TMP_DIR/foo-app.d/foobix/README.md")"
	assertEquals $? 0
	assertEquals "foobix's readme contains 'Known Bugs'" "## Known bugs" "$output"
}

testInstallAlternativeFromTarGz() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin install foo-app "$RESOURCES_DIR/test/resources/foobix.tar.gz"
	assertEquals $? 0
	output="$("$TMP_DIR/foo-app.d/foobix/bin/foobix")"
	assertEquals $? 0
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}
testInstallNamedAlternativeFromTarGz() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin install foo-app "$RESOURCES_DIR/test/resources/foobix.tar.gz" foobix-v0
	assertEquals $? 0
	output="$("$TMP_DIR/foo-app.d/foobix-v0/bin/foobix")"
	assertEquals $? 0
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}

testInstallAlternativeFromZip() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin install foo-app "$RESOURCES_DIR/test/resources/foobix.zip"
	assertEquals $? 0
	output="$(grep "Known bugs" "$TMP_DIR/foo-app.d/foobix/README.md")"
	assertEquals $? 0
	assertEquals "foobix's readme contains 'Known Bugs'" "## Known bugs" "$output"
}

testSetNamedAlternativeFromTarGz() {
	opt-admin create foo-app
	assertEquals $? 0
	opt-admin install foo-app "$RESOURCES_DIR/test/resources/foobix.tar.gz" foofoo
	assertEquals $? 0
	opt-admin choose foo-app foofoo
	assertEquals $? 0
	output="$("$TMP_DIR/foo-app/bin/foobix")"
	assertEquals $? 0
	assertEquals "Result of foobix is 'foobax'" "foobax" "$output"
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"


