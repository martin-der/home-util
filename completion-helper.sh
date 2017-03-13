#!/bin/bash


[ "x${BASH_SOURCE[0]}" == "x${0}" ] && {
	[ $# -ne 1 ] && {
		echo "Exactly one argument is expected"
		exit 2
	}
	[ -e "$1" ] && [ -r "$1" ] || {
		echo "'$1' does not exist or is not readable" >&2
		exit 2
	}
	[ "x#@mdu-helper-capable" == "x$(cat "$1" | sed -e '2q' -e '2d' -e '/^#!\/.*\/bash/d')" ] && {
		echo "Capable"
		exit 0
	} || {
		echo "Not Capable"
		exit 1
	}
}


[ "x${_mdu_CH_completion_running-}" == "x1" ] && return 0

mdu_CH_exit=0
_mdu_CH_completion_running=0
_mdu_CH_application="$(basename "${BASH_SOURCE[1]}")"

_mdu_CH_verb_locution="verb"


_reply_common_completion() {
	case "$1" in
		"string"|"")
			COMPREPLY=()
			;;
		"file"|"directory"|"group"|"hostname"|"job"|"running"|"service"|"signal"|"stopped"|"user")
			COMPREPLY=( $(compgen -A "$1" -- ${cur}) )
			;;
		*)
			return 1
			;;
	esac
	return 0
}

_isArgumentOptionnal() {
	grep "^\[.*\]$" <<< "$1" >/dev/null
}
_isArgumentRepeatable() {
	grep "^\[.*\.\.\.\]$\|^.*\.\.\.$" <<< "$1" >/dev/null
}
_getArgumentFistCouple() {
	sed "s#^\(<[^>]\+>\).*\$#\1#" <<< "$1"
}
_getArgumentFistCoupleFollow() {
	sed "s#^<[^>]\+>\(.*\)\$#\1#" <<< "$1"
}
_getArgumentCore() {
	sed "s#^\[\([^\.]\+\)\(\.\.\.\)\\?\]\$\|^\([^\.]\+\)\(\.\.\.\)\\?\$#\1\3#" <<< "$1"
}
_getArgumentName() {
	sed "s#^<\([^:]\+\)\(:.\+\)\\?>\$#\1#" <<< "$1"
}
_getArgumentType() {
	sed "s#^<\([^:]\+\):\(.\+\)\\?>\$#\2#" <<< "$1"
}


#core="$(_getArgumentCore "$1")" 
#echo "- core : '$core'"
#echo "- first couple :"
#_getArgumentFistCouple "$core"
#echo "- first couple follow :"
#_getArgumentFistCoupleFollow "$core"
#echo "- name :"
#_getArgumentName "$core"
#echo "- type :"
#_getArgumentType "$core"
#exit 0


___list_verbs() {
	"$_mdu_CH_list_verbs_CB" $@
	return $?
}
___get_verb_arguments() {
	"$_mdu_CH_get_verb_arguments_CB" $@
	return $?
}
___get_information() {
	"$_mdu_CH_get_information_CB" "${1:-}" "${2:-}" "${3:-}"
	return $?
}

_dump_man() {
	local name=$_mdu_CH_application
	local summary=$(___get_information summary)
	echo ".TH $name 1 \"$(date +"%d %b %Y")\" \"version 1.0\""
	echo ".SH NAME"
	echo "$name - $summary"
	echo ".SH SYNOPSIS"
	local first=1
	___list_verbs | while read verb ; do
		[ $first -eq 1 ] && first=0 || echo ".br"
		argumentsRaw=$(___get_verb_arguments "$verb")
		echo ".B $name"
		echo "$verb"
		for argument in ${argumentsRaw}; do
			local argumentName="$(_getArgumentName "$argument")"
			#echo -n ".Op "
			_isArgumentOptionnal "${argument}" && {
				_isArgumentRepeatable "${argument}" && echo "[${argumentName}]" || echo "[${argumentName}...]"
			} || {
				_isArgumentRepeatable "${argument}" && echo "${argumentName}" || echo "${argumentName}..."
			}
		done
	done
	local detail=$(___get_information detail)
	[ "x$detail" != "x" ] && {
		echo ".SH DESCRIPTION"
		echo "$detail"
	}
}

_mdu_auto_completion() {

	_mdu_CH_completion_running=1
	#_mdu_CH_application="${COMP_WORDS[0]}"
	_mdu_CH_application="${1##*/}"

	#. "$_mdu_CH_application"
	. "${1}"

	local cur prev
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"

	local verb verbs arguments customValues

	case $COMP_CWORD in
		1)
			verbs=$(___list_verbs)
			COMPREPLY=( $(compgen -W "$verbs" -- ${cur}) )
			;;
		*)
			verb="${COMP_WORDS[1]}"
			[ "x$verb" == "xhelp" ] && {
				[ $COMP_CWORD -eq 2 ] && {
					verbs=$(___list_verbs)
					COMPREPLY=( $(compgen -W "$verbs" -- ${cur}) )
				}
			} || {
				arguments=$(___get_verb_arguments "$verb") && {
					argumentsTemplatesArray=($arguments)
					argumentTemplate="${argumentsTemplatesArray[COMP_CWORD-2]}"
					argumentName="$(_getArgumentName "$argumentTemplate")"
					argumentType="$(_getArgumentType "$argumentTemplate")"
					previousArguments=("${COMP_WORDS[@]:1:COMP_CWORD-1}")
					#notify -r 2 "all : ${COMP_WORDS[*]}\nindex : ${COMP_CWORD}\ncurrent : ${cur}\nprevious : ${previousArguments[*]}"
					_reply_common_completion "$argumentType" || {
						customValues="$("$_mdu_CH_complete_type_CB" "$argumentType" "${previousArguments[@]}" )"
						COMPREPLY=( $(compgen -W "$customValues" -- ${cur}) )
					}
				}
			}
			;;
	esac

}


_mdu_CH_set_callbacks() {
	_mdu_CH_list_verbs_CB="$1"
	export _mdu_CH_list_verbs_CB
	_mdu_CH_get_verb_arguments_CB="$2"
	export _mdu_CH_get_verb_arguments_CB
	_mdu_CH_get_information_CB="$3"
	export _mdu_CH_get_information_CB
	_mdu_CH_complete_type_CB="$4"
	export _mdu_CH_complete_type_CB

	[ "x$_mdu_CH_list_verbs_CB" == x ] && { echo "[_mdu_CH_help] callback 'list_verbs'(1) is missing" >&2 ; return 1 ; }
	[ "x$_mdu_CH_get_verb_arguments_CB" == x ] && { echo "[_mdu_CH_help] callback 2 'get_verb_arguments'(2) is missing" >&2; return 1 ; }
}

_mdu_CH_init_builder_helper() {

	_mdu_CH_set_callbacks $@
	shift 4

	[ ! -z ${1+x} -a "x$1" == "xhelp" ] || return
	shift

	[ -z ${1+x} ] && return 0

	[ "$1" == "--dump-man" ] && {
		_dump_man
		exit 0
	}

	[ "$1" == "--man" ] && {
		_dump_man | man /dev/stdin
		exit 0
	}

	[ "$1" == "--is-mdu-helper" ] && {
		echo "mdu_helper_capable"
		exit 0
	}

	[ "$1" == "--helper-complete" ] && {
		local _complete_options=
		local application_name="$(basename "$_mdu_CH_application")"
		complete ${_complete_options} -F _mdu_auto_completion "$application_name"
		mdu_CH_exit=1
		export mdu_CH_exit
		return 0
	}
}


_print_paragraph()  {
	title="$1"

	local format=1
	[ $format -eq 1 ] && {
		local FMT_CNT_paragraphe_title="\033[1;37m"
		#local FMT_CNT_paragraphe_title="\033[0;37m"
		#local FMT_CNT_paragraphe_title="\033[1;32m"
		local FMT_CNT_reset="\033[0;0m"
	}
	local emPrefix="    "

	echo -e "${FMT_CNT_paragraphe_title}${title}${FMT_CNT_reset}"
	while read l ; do
		echo "${emPrefix}${l}"
	done

}

_mdu_CH_print_help() {

	local prefixUsage="Usage"
	local prefixSummary="Summary"
	local prefixDetail="Detail"
	local prefixParameters="Parameters"
	local prefixParametersTypes="Parameter's Types"
	local prefixActions="Available actions"

	local argumentCore argumentType argumentName

	if [ $# == 0 ] ; then

		_print_paragraph "${prefixUsage}" <<< "$_mdu_CH_application <action> [<parameter>...]"

		___list_verbs | sort | _print_paragraph "$prefixActions"

	elif [ $# == 1 ] ; then

		verb="$1"

		[ "x$verb" == "xhelp" ] && {
			echo "Are you kidding me ?"
			arguments="<${_mdu_CH_verb_locution}:${_mdu_CH_verb_locution}>"
			summary="Show help about <${_mdu_CH_verb_locution}>"
		} || {
			arguments=$(___get_verb_arguments "$verb")
			summary=$(___get_information "summary" "$verb" "verb")
			detail=$(___get_information "detail" "$verb" "verb")
		}

		local argumentsArray=($arguments)

		(
			echo -e -n "$_mdu_CH_application $verb"
			[ "x$arguments" != "x"  ] && {
				for argument in "${argumentsArray[@]}"; do
					argumentCore="$(_getArgumentCore "${argument}")"
					argumentName="$(_getArgumentName "${argumentCore}")"
					_isArgumentOptionnal "${argument}" && {
						_isArgumentRepeatable "${argument}" && echo "[${argumentName}]" || echo "[${argumentName}...]"
						echo -e -n " [<${argumentName}>]"
					} || {
						_isArgumentRepeatable "${argument}" && echo "[${argumentName}]" || echo "[${argumentName}...]"
						echo -e -n " <${argumentName}>"
					}
				done
			}
			echo
		) | _print_paragraph "${prefixUsage}"

		[ "x$summary" != "x" ] && _print_paragraph "${prefixSummary}" <<< "$summary"

		[ "x$detail" != "x" ] && _print_paragraph "${prefixDetail}" <<< "$detail"

		# Workaround a bug where empty an array is considered as undeclared
		local usedTypes=("-_-")

		local maxArgumentLen=0
		local maxTypeLen=0
		local len
		[ "x$arguments" != "x"  ] && {
			for argument in "${argumentsArray[@]}"; do
				argumentCore="$(_getArgumentCore "${argument}")"
				argumentName="$(_getArgumentName "${argumentCore}")"
				len=${#argumentName}
				[ $len -gt $maxArgumentLen ] && maxArgumentLen=$len
				argumentType="$(_getArgumentType "${argumentCore}")"
				len=${#argumentType}
				[ $len -gt $maxTypeLen ] && maxTypeLen=$len
				local seen=0
				for s in "${usedTypes[@]}"; do [[ "$s" == "$argumentType" ]] && { seen=1 ; break ; } done
				[ $seen -eq 1 ] && continue
				usedTypes+=("$argumentType")
			done
		}

		[ ${#argumentsArray[@]} -gt 0 ] && {
			(
				for argument in "${argumentsArray[@]}"; do
					argumentCore="$(_getArgumentCore "${argument}")"
					argumentName="$(_getArgumentName "${argumentCore}")"
					argumentType="$(_getArgumentType "${argumentCore}")"
					local typeSummary="$(___get_information "summary" "$argumentType" "type" )"
					[ "x$typeSummary" == "x" ] && typeSummary="$argumentType" || typeSummary="$typeSummary ( type '$argumentType' )"
					printf "%-${maxArgumentLen}s : %s\n" "$argumentName" "$typeSummary"
				done
			) | _print_paragraph "${prefixParameters}"

			local types_information="$(
				for tyype in "${usedTypes[@]}"; do
					[ "x$tyype" == "x-_-" ] && continue
					local summary="$(___get_information "summary" "$tyype" "type" )"
					local detail="$(___get_information "detail" "$tyype" "type" )"
					[ "x$summary" == "x" -a "x$detail" = "x" ] && continue
					[ "x$summary" == "x" ] && echo "${tyype} :" || echo "${tyype} : $summary"
					[ "x$detail" != "x" ] && {
						local emPrefix="|   "
						while read l ; do
							echo "${emPrefix}${l}"
						done <<< "$detail"
					}

				done
			)"
			[ "x$types_information" != "x" ] && {
				_print_paragraph "${prefixParametersTypes}" <<< "$types_information"
			}
		}
	fi
}

_mdu_CH_show_helper_help() {
	echo "Sourced | When this script is sourced"
	echo "caller must provide four callbacks:"
	echo "- getInformation <info> [<verb>]"
	echo "- listVerbs"
	echo "- getVerbArguments <verb>"
	echo "- completeType <type> <verb> [<previous_arg>...]"
	echo "Executed | When this script is executed"
	echo "it accepts one parameter:"
	echo "- the path of a script"
	echo "return 0 and echo 'Capable' if the script given has parameter can do automatic completion"
	echo "return non 0 and echo 'Not Capable' otherwise"
}


[[ $_ != $0 ]] || { _mdu_CH_show_helper_help ; exit 20 ; }

