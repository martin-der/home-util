#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


# Just to be safe if 'setUp' fails its job
export HOME=/tmp/tmp/tmp

#oneTimeSetUp() {
#}


setUp() {
	TMP_DIR=`mktemp -d`
	export HOME="${TMP_DIR}/home"
	export USER=johndoe
	mkdir -p "$HOME/.config/mdu" || return 2
	mdu_config="$HOME/.config/mdu/init.properties"
	echo "" > "$mdu_config"
}
tearDown() {
	printHomeContent
	rm -rf "$TMP_DIR"
}

initHome() {
 	"${src_root_dir}/init-home.sh" "$@"
}


printHomeContent() {
	echo "Content of home"
	find "$HOME" -exec ls -dl '{}' \;
}


testCreateBinDirectory() {

	echo 'directory.bin=$HOME/bin' >> "$mdu_config"

	initHome
	assertEquals 0 $?
	assertTrue "Directory '$HOME/bin' has been created" "[ -d \"$HOME/bin\" ]"
}

testCreateBinDirectoryWithLinkedExcutables() {

	echo 'directory.bin=$HOME/bin' >> "$mdu_config"

	echo "link.executable.sourceDirectory=$test_root_dir/resources" >> "$mdu_config"
	echo 'link.executable.elements=foobix/bin/foobix\
script-system-util/config-util.sh' >> "$mdu_config"

	echo "Content of mdu-conf"
	cat "$mdu_config"

	initHome
	assertEquals 0 $?

	local created_link
	created_link="$(readlink "$HOME/bin/foobix")"
	assertEquals 0 $?
	assertEquals "'bin/foobix' point to the right executable" "$test_root_dir/resources/foobix/bin/foobix" "$created_link"

}


runTests
