#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../.."
popd > /dev/null
test_root_dir="${root_dir}/test"

# Just to be safe if 'setUp' fails its job
export HOME=/tmp/tmp/tmp

oneTimeSetUp() {
	export MDU_LOG_LEVEL=debug
}


setUp() {
	TMP_DIR=`mktemp -d`
	export HOME="${TMP_DIR}/home"
	export USER=johndoe
	mkdir -p "$HOME/.config/mdu" || return 2
	mdu_config="$HOME/.config/mdu/init.properties"
	echo "" > "$mdu_config"
}
tearDown() {
	echo "Content of home"
	find "$HOME"  ! -exec ls -dl '{}' \;
	rm -rf "$TMP_DIR"
}



testCreateBinDirectory() {

	echo 'directory.bin=$HOME/bin' >> "$mdu_config"

	./init-home.sh
	assertEquals 0 $?
	assertTrue "Directory '$HOME/bin' has been created" "[ -d \"$HOME/bin\" ]"
	
}

testCreateBinDirectoryWithLinkedExcutables() {

	echo 'directory.bin=$HOME/bin' >> "$mdu_config"

	echo "link.executable.sourceDirecory=$test_root_dir/resources" >> "$mdu_config"
	echo 'link.executable.elements=foobix/bin/foobix\
script-system-util/config-util.sh' >> "$mdu_config"

	echo "Content of mdu-conf"
	cat "$mdu_config"

	./init-home.sh
	assertEquals 0 $?

	local created_link
	created_link="$(readlink "$HOME/bin/foobix")"
	assertEquals 0 $?
	assertEquals "'bin/foobix' point to the right executable" "$test_root_dir/resources/foobix/bin/foobix" "$created_link"

}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"
[ $__shunit_testsFailed -gt 0 ] && exit 5

