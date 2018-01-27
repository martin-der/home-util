#!/usr/bin/env bash
#@mdu-helper-capable

source help-helper.sh || exit 1


function listActions() {
	echo "fetch hold bark sleep smell call learn"
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
		"fetch")
			echo "<what:thing> [<to:dog_name>]" ;;
		"hold")
			echo "<what:thing>" ;;
		"call")
			echo "<name:dog_name>" ;;
		"bark")
			echo "[<sound:string>]" ;;
		"sleep")
			echo "<duration:integer>" ;;
		*)
			return 1 ;;
	esac

	return 0
}

function getOption() {
	local info option verb
	info="$1"
	option="$2"
	verb="$3"
	[ "x$option" = "x" -a "x$verb" = "x" ] && {
		#[v]erbose [r]eplay-command <times> [d]ry-mode [a]ll(dogs)
		echo "vr:da"
		return 0
	}
	[ "x$option" = "x" ] && {
		case "$verb" in
			"fetch")
				echo "u:" ; return 0
				;;
		esac
		return 0
	}
}

function getInformation() {
	local info="$1"
	local name="$2"
	local what="$3"
	local action parameterType

	[ "x$what" == "x" ] && {
		[ "x$info" == "xsummary" ] && echo "Dog interaction for newbies"
		[ "x$info" == "xdetail" ] && echo "This application helps you to interact with your dog."
		return 0
	}

	[ "x$what" == "xtype" ] && {
		case "$name" in
			thing)
				[ "x$info" == "xsummary" ] && echo "A thing the dog is familiar with"
				[ "x$info" == "xdetail" ] && echo "Anything known by the dog can be fetch. Just make sure the dog can handle it. Don't ask a yorkshire to fetch a huge log otherwise you may hurt the dog."
				;;
		esac
		return 0
	}

	[ "x$what" == "xverb" ] && {
		case "$name" in
			fetch)
				[ "x$info" == "xsummary" ] && echo "Demand your dog to fetch something"
				;;
			sleep)
				[ "x$info" == "xsummary" ] && echo "Demand your dog to go to sleep"
				[ "x$info" == "xdetail" ] && echo "Time is in second. There is no garanty the dog wakes up after n seconds. You may have to wake it up ( see \`call\` )"
				;;
		esac
	}

	return 0
}

[ "xhelp" == "x${1:-}" ] && {
	shift
	mdu_HH_do_help "listActions" "getActionArguments" "getOption" "completeType" "getInformation" $@
}


