#!/bin/bash



LOG_LEVEL_DEBUG=4
LOG_LEVEL_INFO=3
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=1
LOG_LEVEL_NONE=0


DEFAULT_LOG_LEVEL=${LOG_LEVEL_WARN}

DRY_MODE=0


MDU_HUMAN_MODE=${MDU_HUMAN_MODE:-1}
MDU_NO_COLOR=${MDU_NO_COLOR:-0}


[ ${MDU_NO_COLOR} -ne 0 ] && {
	GREEN=""
	GREEN_BOLD=""
	YELLOW=""
	YELLOW_BOLD=""
	RED=""
	RED_BOLD=""
	BLUE=""
	BLUE_BOLD=""
	#WHITE=""
	#GRAY_LIGHT=""
	COLOR_RESET=""
	FONT_STYLE_BOLD=""
	FONT_STYLE_ITALIC=""
	FONT_STYLE_UNDERLINE=""
	FONT_STYLE_STRIKE=""
} || {
	GREEN="\033[0;32m"
	GREEN_BOLD="\033[1;32m"
	YELLOW="\033[0;33m"
	YELLOW_BOLD="\033[1;33m"
	RED="\033[0;31m"
	RED_BOLD="\033[1;31m"
	BLUE="\033[0;34m"
	BLUE_BOLD="\033[1;34m"
	#WHITE="\033[1;37m\]"
	#GRAY_LIGHT="\033[0;37m"
	COLOR_RESET="\033[0;0m"
	FONT_STYLE_BOLD="\033[1m"
	FONT_STYLE_ITALIC="\033[3m"
	FONT_STYLE_UNDERLINE="\033[4m"
	FONT_STYLE_STRIKE="\033[9m"
}




# ---------------------- #
#                        #
#        Include         #
#                        #
# ---------------------- #

_mdu_loaded_scripts=( "." )

#
# Load source
#	param 1/0 : once
#	param <name> : script name
#	return same as @see load_source
#
function _mdu_source_if_exists() {
	[ -r "$2" ] && {
		local linked="$(readlink -f "$2")"
		log_debug " Found '$2' in '$linked' (once:$1)"
		[ $1 -ne 0 ] && {
			log_debug "  Sourced ? (${_mdu_loaded_scripts[*]})"
			for loaded in "${_mdu_loaded_scripts[@]}"; do
				[ "$loaded" == "$linked" ] && return 0;
			done
		}
		#log_debug "  Sourcing '$2'"
		_mdu_loaded_scripts+=("$linked")
		#log_debug "   \\-> Sourced : (${_mdu_loaded_scripts[*]})"
		source "$2"
		local result=$?
		[ ${result} -eq 0 ] && return 0
		log_error "Error sourcing '$2' : returned $?"
		[ ${result} -eq 254 ] && return 253
		return ${result}
	}
	return 254
}


#
# Load source
#	param 1/0 : [O]nce
#	param 1/0 : [A]round [L]inked
#	param <name>
#	param ... : [W]ith [S]uffixes
#
function _mdu_load_source_O_AL_WS() {
	local result only_once around_linked script suffixed linked_script
	only_once=$1
	around_linked=$2
	shift 2
	script=$1
	shift
	log_debug "Try '$script'..."
	_mdu_source_if_exists ${only_once} "$script"
	result=$?
	[ $result -ne 254 ] && return $result

	#[ -h "$script" ] && {
	#	linked_script="$(readlink -f "$script")" || continue
	#	linked_script="$(dirname "$target_file")/$1"
	#	_mdu_source_if_exists ${only_once} "$linked_script" && return 0
	#}
	for suffix in "$@" ; do
		suffixed="${script}.${suffix}"
		log_debug "Try suffixed '$suffixed'..."
		_mdu_source_if_exists ${only_once} "$suffixed"
		result=$?
		[ $result -ne 254 ] && {
			log_debug "  '$suffixed' returned $result"
			return $result
		}
	done
	return 254
}

function _mdu_load_source() {

	local only_once=1
	local around_callers=0
	local around_linked=0
	local o="${MDU_SOURCE_OPTIONS:-1lC}$1"
	for (( i=0; i<${#o}; i++ )); do
		local ov="${o:$i:1}"
		[ ${ov} == 1 ] && { only_once=1 ; continue ; }
		[ ${ov} == n ] && { only_once=0 ; continue ; }
		[ ${ov} == c ] && { around_callers=1 ; continue ; }
		[ ${ov} == C ] && { around_callers=0 ; continue ; }
		[ ${ov} == l ] && { around_linked=1 ; continue ; }
		[ ${ov} == L ] && { around_linked=0 ; continue ; }
	done
	shift

	local sourced_file request
	request="$1"
	shift
	[ "x${request:0:1}" != "x/" ] && {
		[ ${around_callers} -eq 0 ] && {
			#log_debug "Looking from '${BASH_SOURCE[2]}'"
			#printf '  - %s\n' "${BASH_SOURCE[@]}"
			sourced_file="$(dirname "${BASH_SOURCE[2]}")/$request"
			_mdu_load_source_O_AL_WS ${only_once} ${around_linked} "$sourced_file" $@
			result=$?
			[ ${result} -ne 254 ] && return ${result}

			log_debug "'$request' not found as '$sourced_file'"
		#} || {
		#	for script in "${BASH_SOURCE[@]}" ; do
		#		sourced_file="$(dirname "$script")/$request"
		#		_mdu_load_source_O_AL_WS ${only_once} ${around_linked} "$sourced_file" $@ && return 0 || log_debug "'$request' not found as '$sourced_file' from '$(basename "$script")'"
		#	done
		}
	}
	_mdu_load_source_O_AL_WS ${only_once} ${around_linked} "$request" $@
	result=$?
	[ ${result} -eq 0 ] && return 0
	[ ${result} -eq 254 ] &&  {
		log_error "Error sourcing '$request' : not found"
		return 254
	}
	return ${result}
}

# @param $1 : script to source
# @param ... : extra suffixes to try loading against
# @return
#     - 254            : if script was not found or couldn't be read
#     - 0              : if script was sourced without error
#     - [1-253] or 255 : if script returned an error ( if error code was 254, then 253 is returned instead )
#
function load_source() {
	_mdu_load_source "" $@
}
# Same as 'load_source' but make sure to load script only once
function load_source_once() {
	_mdu_load_source 1 $@
}


# ---------------------- #
#                        #
#        Logging         #
#                        #
# ---------------------- #

ICON_WARN="${YELLOW_BOLD}/!\\\\${COLOR_RESET}"
ICON_ERROR="${RED_BOLD}/!\\\\${COLOR_RESET}"
ICON_INFO="${BLUE_BOLD}(*)${COLOR_RESET}"
ICON_DEBUG="${GREEN_BOLD}[#]${COLOR_RESET}"

function _mdu_getLogLevel {
	local level=${MDU_LOG_LEVEL:-${LOG_LEVEL:-default}}
	[ "x$level" = xDEBUG -o "x$level" = xdebug ] && return ${LOG_LEVEL_DEBUG}
	[ "x$level" = xINFO -o "x$level" = xinfo ] && return ${LOG_LEVEL_INFO}
	[ "x$level" = xWARN -o "x$level" = xwarn ] && return ${LOG_LEVEL_WARN}
	[ "x$level" = xERROR -o "x$level" = xerror ] && return ${LOG_LEVEL_ERROR}
	[ "x$level" = xNONE -o "x$level" = xnone ] && return ${LOG_LEVEL_NONE}
	return ${DEFAULT_LOG_LEVEL}
}

# print script prefix for 'non human' output
# Param 1 : String severity
function echo_script_prefix() {
	echo -n "[$1] "
	local tag="${MDU_LOG_TAG:-}"
	[ "x$tag" != "x" ] && echo -n "$tag "
}

function log_debug() {
	_mdu_getLogLevel
	local level=$?
	test ${LOG_LEVEL_DEBUG} -gt ${level} && return 0
	local human_mode=${MDU_HUMAN_MODE}
	if [ ${human_mode} -eq 0 ] ; then
		echo_script_prefix DEBUG
	else
		echo -e -n "$ICON_DEBUG "
	fi
	echo "$@"
}

function log_info() {
	_mdu_getLogLevel
	local level=$?
	test ${LOG_LEVEL_INFO} -gt ${level} && return 0
	local human_mode=${MDU_HUMAN_MODE}
	if [ ${human_mode} -eq 0 ] ; then
		echo_script_prefix INFO
	else
		echo -e -n "$ICON_INFO "
	fi
	echo "$@"
}

function log_warn() {
	_mdu_getLogLevel
	local level=$?
	test ${LOG_LEVEL_WARN} -gt ${level} && return 0
	local human_mode=${MDU_HUMAN_MODE}
	if [ ${human_mode} -eq 0 ] ; then
		echo_script_prefix WARN >&2
	else
		echo -e -n "$ICON_WARN " >&2
	fi
	echo "$@" >&2
}

function log_error()  {
	_mdu_getLogLevel
	local level=$?
	test ${LOG_LEVEL_ERROR} -gt ${level} && return 0
	local human_mode=${MDU_HUMAN_MODE}
	if [ ${human_mode} -eq 0 ] ; then
		echo_script_prefix ERROR >&2
	else
		echo -e -n "$ICON_ERROR " >&2
	fi
	echo "$@" >&2
}


# ---------------------- #
#                        #
#      String util       #
#                        #
# ---------------------- #

mdu_getTextDecoration() {
	local prefix="_mdu_text_decoration__"
	local i="${prefix}$1"
	echo -n -e "${!i-}"
}
mdu_setTextDecoration() {
	local prefix="_mdu_text_decoration__"
	local i="${prefix}$1"
	read -d"\0" "$i" <<<"$2"
}
mdu_isSetTextDecoration() {
	local prefix="_mdu_text_decoration__"
	local i="${prefix}$1"
	[ -z ${!i+x} ] && return 1 || return 0
}
mdu_unsetTextDecoration() {
	local prefix="_mdu_text_decoration__"
	local i="${prefix}$1"
	unset "$i"
}


function _decorationBiggestGroup() {
	sed "s#^\([^{]*\){\([a-zA-Z\-]*\){\(.*\)}}\([^}]*\)\$#\\$2#" <<< "$1"
}
function _decorationFirstGroup() {
	sed "s#^\([^{]*\){\([a-zA-Z\-]*\){\([^{]*\)}}\(.*\)\$#\\$2#" <<< "$1"
}
function _echoDecorationValue() {
	mdu_isSetTextDecoration "$1" && {
		mdu_getTextDecoration "$1"
		return 0
	}
	case "$1" in
		"red") echo -e -n "$RED" ;;
		"green") echo -e -n "$GREEN" ;;
		"blue") echo -e -n "$BLUE" ;;
		"yellow") echo -e -n "$YELLOW" ;;
		"bold") echo -e -n "$FONT_STYLE_BOLD" ;;
		"italic") echo -e -n "$FONT_STYLE_ITALIC" ;;
		"strike") echo -e -n "$FONT_STYLE_STRIKE" ;;
		"underline") echo -e -n "$FONT_STYLE_UNDERLINE" ;;
		*) return 1 ;;
	esac
	return 0
}
function decorate()  {
	decorate_n "$1" "${2:-}"
	echo
}
function decorate_n()  {
	local text="$1"
	local previousDecoration="$2"

	[ "x$2" != "x" ] && previousDecoration="$2" || previousDecoration="$COLOR_RESET"

	local pre key content post

	pre=$(_decorationFirstGroup "$text" 1)
	key=$(_decorationFirstGroup "$text" 2)
	content=$(_decorationFirstGroup "$text" 3)
	post=$(_decorationFirstGroup "$text" 4)

	[ "x$key" != "x$text" ] && {
		echo -n "$pre"
		local decoration=$(_echoDecorationValue "$key")
		echo -e -n "$decoration"
		echo -e -n "$content"
		echo -e -n "AAA$previousDecoration"
		decorate_n "$post" "BBB$previousDecoration"
		return
	}

	pre=$(_decorationBiggestGroup "$text" 1)
	key=$(_decorationBiggestGroup "$text" 2)
	content=$(_decorationBiggestGroup "$text" 3)
	post=$(_decorationBiggestGroup "$text" 4)

	[ "x$key" != "x$text" ] && {
		echo -n "$pre"
		local decoration=$(_echoDecorationValue "$key")
		echo -e -n "$decoration"
		decorate_n "$content" "$decoration"
		echo -e -n "$previousDecoration"
		echo -n "$post"
	} || {
		echo -e -n "$previousDecoration"
		echo -n "$text"
	}
}

function escaped_for_regex {
	sed -e 's/[]\/$*.^|[]/\\&/g' <<< "$1"
}


function line_isComment_withSharp() {
	grep -Eq '^[ 	]*#' <<< "$1" && return 0 || return 1
}
function line_isEmpty() {
	grep -Eq '^[ 	]*$' <<< "$1" && return 0 || return 1
}

# properties

function _mdu_properties_value_from_line() {
	local line="$1"
	local key="$2"
	line_isComment_withSharp "$line" && return 1
	line_isEmpty "$line" && return 1
	local KEY_FOUND="$(line_KeyValue_getKey "$line")"
	[ "x$key" == "x$KEY_FOUND" ] && {
		echo "$(line_KeyValue_getValue "$line")"
		return 0
	}
	return 1
}

# Param 1  : key
# StdInput : text to be searched in
function find_property {
	[ -z ${2+x} ] && {
		while read l ; do
			_mdu_properties_value_from_line "$l" "$1" && return 0
		done
		return 1
	}

	while read l ; do
		_mdu_properties_value_from_line "$l" "$1" && return 0
	done <<< "$2"
	return 1
}
function properties_find {
	find_property $@
	return $?
}
function properties_findTyped {
	find_property $@
	return $?
}

function line_KeyValue_getKey() {
	echo "$1" | sed 's/^[ 	]*\([^ 	=]*\)[ 	]*=\(.*\)/\1/'
}
function line_KeyValue_getValue() {
	echo "$1" | sed 's/^[ 	]*\([^ 	=]*\)[ 	]*=\(.*\)/\2/'
}


# ---------------------- #
#                        #
#          Misc          #
#                        #
# ---------------------- #

function command_exists() {
	which "$1" >/dev/null 2>&1
	return $?
}

