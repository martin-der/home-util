#!/bin/bash
#@mdu-helper-capable

source "$(dirname "$0")/../../../completion-helper.sh" || exit 1


function listActions() {
	echo "fetch bark sleep smell call learn"
}


function completeType() {
	argumentType="$1"
	shift
	action="$1"
	shift
	case $argumentType in
		"dog_name")
			echo "bill rex rintintin strongheart snoopy" ;;
		"thing")
			echo "ball news-paper kitty bottle";;
		*)
			return 1 ;;
	esac

	return 0
}
function getActionArguments() {
	case "$1" in
		"call")
			echo "<name:dog_name>" ;;
		"bark")
			echo "<sound:string>" ;;
		"sleep")
			echo "<sound:integer>" ;;
		*)
			return 1 ;;
	esac

	return 0
}
function getInformation() {
	:
}


_mdu_CH_init_builder_helper "listActions" "getActionArguments" "getInformation" "completeType" $@


