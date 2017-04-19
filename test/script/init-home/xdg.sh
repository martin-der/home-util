#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


# Just to be safe if 'setUp' fails its job
export HOME=/tmp/tmp/tmp

#oneTimeSetUp() {
#}


setUp() {
	TMP_DIR=`mktemp -d` || return 2
	export HOME="${TMP_DIR}/home"
	export USER=johndoe
	mkdir -p "$HOME/.config/mdu" || return 2
	mdu_config="$HOME/.config/mdu/init.properties"
	echo "" > "$mdu_config"
}
tearDown() {
	echo "Content of home"
	find "$HOME" -exec ls -dlgr '{}' \;
	rm -rf "$TMP_DIR"
}

initHome() {
 	"${src_root_dir}/init-home.sh" "$@"
}


testCreateXDGDirectories() {
	export MDU_LOG_LEVEL=debug
	echo 'XDG_DESKTOP_DIR="$HOME/desktop"
XDG_DOWNLOAD_DIR="$HOME/download"
XDG_TEMPLATES_DIR="$HOME/templates"
XDG_PUBLICSHARE_DIR="$HOME/share/public"
XDG_DOCUMENTS_DIR="$HOME/docs"
XDG_MUSIC_DIR="$HOME/music"
XDG_PICTURES_DIR="$HOME/pictures"
XDG_VIDEOS_DIR="$HOME/videos"' > "$HOME/.config/user-dirs.dirs"

	initHome
	assertEquals 0 $?

	assertTrue "Directory '$HOME/desktop' has been created" "[ -d \"$HOME/desktop\" ]"
	assertTrue "Directory '$HOME/download' has been created" "[ -d \"$HOME/download\" ]"
	assertTrue "Directory '$HOME/templates' has been created" "[ -d \"$HOME/templates\" ]"
	assertTrue "Directory '$HOME/share/public' has been created" "[ -d \"$HOME/share/public\" ]"
	assertTrue "Directory '$HOME/docs' has been created" "[ -d \"$HOME/docs\" ]"
	assertTrue "Directory '$HOME/music' has been created" "[ -d \"$HOME/music\" ]"
	assertTrue "Directory '$HOME/pictures' has been created" "[ -d \"$HOME/pictures\" ]"
	assertTrue "Directory '$HOME/videos' has been created" "[ -d \"$HOME/videos\" ]"
}

testNoProblemIfNoXDGConfProvided() {

	initHome
	assertEquals 0 $?
}


runTests
