#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/shell-util.sh" 2>/dev/null || source shell-util  || exit 1

# @description If `key` is in the list, then an environment variable named `[prefix]envVar>` is exported.
#
# @arg $1 string key
# @arg $2 string value
# @arg $3 string list of '<confKey>=<envVar>' ( separated by CR )
# @arg $4 string [optional] prefix, added to the name of created environment var
#
# @exitcode 0 If a a variable is created
# @exitcode >0 otherwise
#
# @example convertConfigKeyAndExportToEnvVariableIfExists name
function convertConfigKeyAndExportToEnvVariableIfExists() {
	local KEY="$1"
	local VALUE="$2"
	local KEY_TO_ENV_LIST="$3"
	local PREFIX="${4:-}"
	local env_name env_type

	env_name="$(find_property "$KEY" <<< "$KEY_TO_ENV_LIST" )"
	[ $? -ne 0 ] && return 1

	env_type="$(mdu_variable_getType "$env_name")"
	env_name="$(mdu_variable_getName "$env_name")"
	log_debug "env_name = '$env_name'"
	env_name="$PREFIX$env_name"
	log_debug "env_type='$env_type'"
	[ "x$env_type" != "x" ] && {
		VALUE="$(convertVariable "$env_type" "$VALUE")"
		[ $? -ne 0 ] && return 2
	}
	log_debug "export '$env_name'='$VALUE'"
	export "$env_name"="$VALUE"
	return 0
}

mdu_variable_getName() {
	sed 's#^\([^:]\+\)\(:.\+\)\?$#\1#' <<< "$1"
}
mdu_variable_getType() {
	sed 's#^\([^:]\+\)\(:\(.\+\)\)\?$#\3#' <<< "$1"
}


# @description Print a variable and its content
#
# @arg $1 string the name of variable
#
# @stdout
# * If the variable exists it is printed with its value and prefixed `(+)`
# * If the variable does not exist it is printed prefixed by `(-)`
#
# @exitcode 0
function printVariable() {
	[ -z ${!1+x} ] && echo "(-)${1}" || echo "(+)${1}:'${!1}'"
}


# @description Convert a value into a typed value
# * `string` : `value` is returned as is
# * `bool` or `boolean` :
#   * `1`, `true` or `yes` : gives `1`
#   * `0`, `false` or `no` : gives `0`
# * `integer` : is returned (without leading zero) if `value` matches `[+-]?[01-9]+`
#
# @arg $1 string value
# @arg $2 string type
#
# @exitcode 0 If conversion vas possible
# @exitcode 1 If conversion failed
# @exitcode 2 If type is unknown
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
			echo "Cannot convert '$value' in '$tyype'" >&2 ; return 1
			;;
		string) echo "$value" ; return 0 ;;
	esac
	echo "$value"
	echo "Unknown type '$tyype'" >&2
	return 2
}
