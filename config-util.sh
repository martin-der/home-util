#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/shell-util.sh" 2>/dev/null || source shell-util  || exit 1

# param 1 : key
# param 2 : value
# param 3 : list of '<confKey>=<envVar>' ( separated by CR )
# param 4 : [optional] prefix, added to the name of created environment var
# If key is in the list, then an environment variable named '<[prefix]envVar>' is exported.
function convertConfigKeyAndExportToEnvVariableIfExists() {
	local KEY="$1"
	local VALUE="$2"
	local KEY_TO_ENV_LIST="$3"
	local PREFIX="${4:-}"
	local env_name
	env_name="$(find_property "$KEY" <<< "$KEY_TO_ENV_LIST" )"
	#env_name="$(mdu_variable_getName "$env_name")"
	local result=$?
	log_debug "env_name = '$env_name'"
	if [ $result -eq 0 ] ; then
		env_name="$PREFIX$env_name"
		log_debug "export '$env_name'='$VALUE'"
		export "$env_name"="$VALUE"
	fi
	return $result
}

mdu_variable_getName() {
	sed 's#^\(.\+\)\(\:.\+\)\\\?$#\1#' <<< "$1"
}
mdu_variable_getType() {
	sed 's#^<\(.\+\)\(\:\(.\+\)\)\\\?>$\|^\[<\(.\+\)\(\:\(.\+\)\)\\\?>\]$#\3\6#' <<< "$2"
}


function printVariable() {
	[ -z ${!1+x} ] && echo "(-)${1}" || echo "(+)${1}:'${!1}'"
}

function convertVariable() {
	local value="$2"
	[ "x$value" == "x" ] && return 1
	local tyype="$1"

	case "$tyype" in
		boolean|bool)
			case "$value" in
				"true"|"yes"|1) echo 1 ; return 0 ;;
				"false"|"no"|0) echo 0 ; return 0 ;;
			esac
			;;
	esac
	return 1
}


