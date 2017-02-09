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
}
tearDown() {
	rm -rf "$TMP_DIR"
}


testCreateXDGDirectories() {
	mkdir -p "$HOME/.config" || return 2
	"$HOME/.config/user-dirs.dirs" <<< 'XDG_DESKTOP_DIR="$HOME/desktop"
XDG_DOWNLOAD_DIR="$HOME/download"
XDG_TEMPLATES_DIR="$HOME/templates"
XDG_PUBLICSHARE_DIR="$HOME/public"
XDG_DOCUMENTS_DIR="$HOME/docs"
XDG_MUSIC_DIR="$HOME/music"
XDG_PICTURES_DIR="$HOME/pictures"
XDG_VIDEOS_DIR="$HOME/videos"'

	./init-home.sh
	assertEquals 0 $?
	assertTrue "Directory '$HOME/music' has been created" "[ -d \"$HOME/music\" ]"
}

. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"


