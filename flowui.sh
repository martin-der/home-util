#!/usr/bin/env bash


source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1

__fui_builder=
__fui_expresser=
__fui_engine=dumb-cli
__fui_output_prefix=__fui_VAL
__fui_RUN_page=

FUI_ERROR_BAD_BUILDER=4
FUI_ERROR_INVALID_COMPONENT_DESC=5
FUI_ERROR_INVALID_INPUT_DESC=6



__print_error() {
	echo "$1" >&2
}
__print_error_missing_param() {
	echo "Parameter '$2'($1) required" >&2
}
__check_param_is_given() {
	local n="$2"
	local i="$1"
	shift 2
	[ "x${!i:-}" == x ] && { echo "Parameter '$n'($i) required" >&2 ; return 1 ; }
}
__check_builder_or_print_error() {
	[ "${__fui_builder:-}" == "x" ] && { echo "no builder configured, use 'fui_set_builder <builder-function>'" >&2 ; return 1 ; }
	return 0
}
fui_is_input_mandatory() {
	[ "x$1" == "xm" ]
}

fui_has_validation() {
	[ "x$value" != x ] && return 0 || return 1
}
fui_is_value_valid_string_or_empty() {
	local value="$1" validation="$2"
	[ "x$value" != x ] && {
		[[ "$value" =~ ${validation} ]] || return 1
	}
	return 0
}
fui_is_value_integer() {
	[[ $1 =~ ^[-+]?[0-9]+$ ]] && return 0 ||  return 1
}
fui_is_value_valid_integer_or_empty() {
	local value="$1" validation="$2" validations
	[ "x$value" != x ] && {
		fui_is_value_integer "$value" || return 1
		IFS=", " read -ra validations <<< "${validation}"
		for validation in "${validations[@]}"; do
			[[ "$validation" =~ ^\<([-+]?[0-9]+)$ ]] && { [ $value -lt ${BASH_REMATCH[1]} ] || return 1 ; continue ; }
			[[ "$validation" =~ ^\>([-+]?[0-9]+)$ ]] && { [ $value -gt ${BASH_REMATCH[1]} ] || return 1 ; continue ; }
			[[ "$validation" =~ ^\<=([-+]?[0-9]+)$ ]] && { [ $value -le ${BASH_REMATCH[1]} ] || return 1 ; continue ; }
			[[ "$validation" =~ ^\>=([-+]?[0-9]+)$ ]] && { [ $value -ge ${BASH_REMATCH[1]} ] || return 1 ; continue ; }
			echo "bad rule'$validation'" >&2
			return 2
		done
	}
	return 0
}

fui_set_builder() {
	[ "${1:-}" == "x" ] && { __print_error_missing_param "1" "builder" ; return 1 ; }
	__fui_builder="$1"
}
fui_set_expresser() {
	[ "${1:-}" == "x" ] && { __print_error_missing_param "1" "expresser" ; return 1 ; }
	__fui_expresser="$1"
}


fui_sanitized_variable_key() {
	sed 's/-/_/g' <<< "$1"
}


#
# param 1 component
# param 2 input
#
fui_get_variable_key() {
	fui_sanitized_variable_key "${__fui_output_prefix}__${__fui_RUN_page}__${1}__${2}"
}
#
# param 1 component
# param 2 input
#
fui_get_variable_key_prefix() {
	fui_sanitized_variable_key "${__fui_output_prefix}__"
}

fui_list_variables_key() {
	local prefix="$(escaped_for_regex "$(fui_get_variable_key_prefix)")"
	eval "echo \${!${prefix}*}" | tr ' ' '\n'
}
fui_list_variables() {
	fui_list_variables_key | while read v ; do
		echo "$v=${!v}"
	done
}
fui_unset_variables() {
	while read v ; do
		unset "${v}"
	done <<< "$(fui_list_variables_key)"
}
#
# param 1 component
# param 2 input
#
fui_unset_variable() {
	local component="$1" input="$2"
	i="$(fui_get_variable_key "$component" "$input")"
	unset "$i"
}
#
# param 1 component
# param 2 input
#
fui_get_variable() {
	local component="$1" input="$2"
	i="$(fui_get_variable_key "$component" "$input")"
	[ -z ${!i+x} ] && return 1 || {
		echo -n -e "${!i-}"
		return 0
	}
}
#
# param 1 component
# param 2 input
# param 3 value
#
fui_set_variable() {
	local component="$1" input="$2"
	i="$(fui_get_variable_key "$component" "$input")"
	#read -d"\0" "$i" <<<"$3"
	read -r "$i" <<<"$3"
}


fui_run_page() {
	__check_builder_or_print_error || return 1
	__check_param_is_given 1 "Page Name" "$@"
	local page="$1"

	local page_runner
	case "$__fui_engine" in
		dumb-cli)
			load_source_once "./flowui-dumbcli" sh || {  __print_error "Failed to load 'flowui-dumbcli'" ; return ${FUI_ERROR_BAD_BUILDER}; }
			page_runner=__fui_run_page_DUMBCLI
			;;
		humble-tui)
			load_source_once "./flowui-humbletui" sh || {  __print_error "Failed to load 'flowui-humbletui'" ; return ${FUI_ERROR_BAD_BUILDER}; }
			page_runner=__fui_run_page_HUMBLETUI
			;;
		*)
			__print_error "Unknown runner '${__fui_engine}'" ; return ${FUI_ERROR_BAD_BUILDER};
			;;
	esac

	[ "x$(type -t "$page_runner")" == xfunction ] || {  __print_error "'$page_runner' is not a valid function" ; return ${FUI_ERROR_BAD_BUILDER}; }

	while :; do
		local components title header footer
		local navigation
		components=$("$__fui_builder" page "$page" list-components) || { __print_error "Failed to get components for page '$page'" ; return 1 ; }
		title=$("$__fui_builder" page "$page" title)
		header=$("$__fui_builder" page "$page" header)
		footer=$("$__fui_builder" page "$page" footer)

		__fui_RUN_page="$page"

		local previous_IFS="$IFS"
		"$page_runner" "$components" "$title" "$header" "$footer"
		IFS="$previous_IFS"

		navigation="$("$__fui_builder" page "$page" navigation)" || { __print_error "Failed to get navigation for page '$page'" ; return 1 ; }
		[[ $navigation =~ ^[\ ]*=\>[\ ]*(.+)$ ]] && {
			page="${BASH_REMATCH[1]}"
			continue
		}
		break;
	done


}

fui_get_component() {
	"$__fui_builder" component "$1" ""
}

#
# param 1 input
# param 2 component @optionnal
#
fui_get_input_label() {
	"$__fui_expresser" input "$1" "${2:-}"
}
#
# param 1 input
# param 2 component @optionnal
#
fui_get_component_label() {
	"$__fui_expresser" component "$1" "${2:-}"
}


