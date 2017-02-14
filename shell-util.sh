#!/bin/bash


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

LOG_LEVEL_DEBUG=4
LOG_LEVEL_INFO=3
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=1
LOG_LEVEL_NONE=0


DEFAULT_NO_COLOR=0
DEFAULT_HUMAN_MODE=1
DEFAULT_LOG_LEVEL=$LOG_LEVEL_WARN

DRY_MODE=0


MDU_HUMAN_MODE=${MDU_HUMAN_MODE:-1}
MDU_NO_COLOR=${MDU_NO_COLOR:-0}


if test "x$MDU_HUMAN_MODE" != x
then
	HUMAN_MODE="$MDU_HUMAN_MODE"
else
	HUMAN_MODE=$DEFAULT_HUMAN_MODE
fi

if test "x$MDU_NO_COLOR" != x
then
	NO_COLOR="$MDU_NO_COLOR"
else
	NO_COLOR=$DEFAULT_NO_COLOR
fi





function _mdu_getLogLevel {
	local level=${MDU_LOG_LEVEL:-${LOG_LEVEL:-default}}
	[ "x$level" = xDEBUG -o "x$level" = xdebug ] && return $LOG_LEVEL_DEBUG
	[ "x$level" = xINFO -o "x$level" = xinfo ] && return $LOG_LEVEL_INFO
	[ "x$level" = xWARN -o "x$level" = xwarn ] && return $LOG_LEVEL_WARN
	[ "x$level" = xERROR -o "x$level" = xerror ] && return $LOG_LEVEL_ERROR
	[ "x$level" = xNONE -o "x$level" = xnone ] && return $LOG_LEVEL_NONE
	return $DEFAULT_LOG_LEVEL
}


[ $NO_COLOR -eq 0 ] || {
	GREEN=""
	GREEN_BOLD=""
	YELLOW=""
	YELLOW_BOLD=""
	RED=""
	RED_BOLD=""
	BLUE=""
	BLUE_BOLD=""
	COLOR_RESET=""
}




#
# Logging
#

ICON_WARN="${YELLOW_BOLD}/!\\\\${COLOR_RESET}"
ICON_ERROR="${RED_BOLD}/!\\\\${COLOR_RESET}"
ICON_INFO="${BLUE_BOLD}(*)${COLOR_RESET}"
ICON_DEBUG="${GREEN_BOLD}[#]${COLOR_RESET}"

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
	test $LOG_LEVEL_DEBUG -gt $level && return 0
	local human_mode="$HUMAN_MODE"
	if [ $human_mode -eq 0 ] ; then
		echo_script_prefix DEBUG
	else
		echo -e -n "$ICON_DEBUG "
	fi
	echo "$@"
}

function log_info() {
	_mdu_getLogLevel
	local level=$?
	test $LOG_LEVEL_INFO -gt $level && return 0
	local human_mode="$HUMAN_MODE"
	if [ $human_mode -eq 0 ] ; then
		echo_script_prefix INFO
	else
		echo -e -n "$ICON_INFO "
	fi
	echo "$@"
}

function log_warn() {
	_mdu_getLogLevel
	local level=$?
	test $LOG_LEVEL_WARN -gt $level && return 0
	local human_mode="$HUMAN_MODE"
	if [ $human_mode -eq 0 ] ; then
		echo_script_prefix WARN >&2
	else
		echo -e -n "$ICON_WARN " >&2
	fi
	echo "$@" >&2
}

function log_error()  {
	_mdu_getLogLevel
	local level=$?
	test $LOG_LEVEL_ERROR -gt $level && return 0
	local human_mode="$HUMAN_MODE"
	if [ $human_mode -eq 0 ] ; then
		echo_script_prefix ERROR >&2
	else
		echo -e -n "$ICON_ERROR " >&2
	fi
	echo "$@" >&2
}


#
# string util
#


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
	echo "$1" | grep -Eq '^[ 	]*#' && return 0 || return 1
}
function line_isEmpty() {
	echo "$1" | grep -Eq '^[ 	]*$' && return 0 || return 1
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

	echo "$2" | while read l ; do
		_mdu_properties_value_from_line "$l" "$1" && return 0
	done
	return 1
}
function properties_find {
	find_property $@
	return $?
}

function line_KeyValue_getKey() {
	echo "$1" | sed 's/^[ 	]*\([^ 	=]*\)[ 	]*=\(.*\)/\1/'
}
function line_KeyValue_getValue() {
	echo "$1" | sed 's/^[ 	]*\([^ 	=]*\)[ 	]*=\(.*\)/\2/'
}


#
# Misc
#

function command_exists() {
	command -v "$1" >/dev/null 2>&1
	return $?
}

