#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	#source "${src_root_dir}/completion-helper.sh" || exit 1
	source "${test_root_dir}/resources/smart_dog.sh" help --helper-complete || exit 1
	local smart_dog_completion_line="$(complete -p | grep smart_dog)"
	completion_function="$(sed "s#^complete -F \(.*\) smart_dog\.sh\$#\1#" <<< "${smart_dog_completion_line}")"
	echo "completion_function = $completion_function"
}

prepareCompletionVars() {
	COMP_CWORD="$1"
	COMP_POINT="$2"
	shift 2
	COMP_LINE="$*"
	#read -r -a COMP_WORDS <<< $@
	COMP_WORDS=( "$@" )
	COMP_TYPE=go
	echo "COMP_CWORD = '$COMP_CWORD'"
	echo "COMP_POINT = '$COMP_POINT'"
	echo "COMP_LINE = '$COMP_LINE'"
	IFS=',' echo "COMP_WORDS = ${COMP_WORDS[*]}"
	#printf '%s,' "${COMP_WORDS[@]}"
	echo "COMP_TYPE = '$COMP_TYPE'"

}

testCompleteVerbs() {
	prepareCompletionVars 1 0 smart_dog.sh "" azaze
	"$completion_function" "${test_root_dir}/resources/smart_dog.sh"
	IFS=',' echo "COMPREPLY = ${COMPREPLY[*]}"
}



runTests

