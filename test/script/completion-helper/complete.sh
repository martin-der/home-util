#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	source "${test_common_resources_dir}/smart_dog.sh" help --helper-complete || {
		echo "Failed to init completion" >&2
		exit 1
	}
	local smart_dog_completion_line="$(complete -p | grep smart_dog)"
	completion_function="$(sed "s#^complete -F \(.*\) smart_dog\.sh\$#\1#" <<< "${smart_dog_completion_line}")"
}

prepareCompletionVars() {
	COMP_CWORD="$1"
	#COMP_POINT="$2"
	shift 2
	COMP_LINE="$*"
	#read -r -a COMP_WORDS <<< $@
	COMP_WORDS=( "$@" )
	#COMP_TYPE=go
	echo "COMP_CWORD = '$COMP_CWORD'"
	#echo "COMP_POINT = '$COMP_POINT'"
	echo "COMP_LINE = '$COMP_LINE'"
	IFS=',' echo "COMP_WORDS = ${COMP_WORDS[*]}"
	#printf '%s,' "${COMP_WORDS[@]}"
	#echo "COMP_TYPE = '$COMP_TYPE'"
}

NO_REPLY="<--- NO REPLY --->"

getCompReplies() {
	if [ -z ${COMPREPLY+x} ]; then
		echo "$NO_REPLY"
		return
	fi
	for r in "${COMPREPLY[@]}"
	do
		echo "$r"
	done
}

testCompletionFunctionIsRegistered() {
	assertEquals "Completion function is registered" "_mdu_auto_completion" "$completion_function" || exit "$MDU_SHELLTEST_TEST_ASSERTION_FAILURE_EXIT_CODE"
}

testCompleteVerbs() {

	local response expected
	expected="fetch
hold
bark
sleep
smell
call
learn"

	prepareCompletionVars 1 0 smart_dog.sh ""
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "$expected" "$response"
}

testCompleteVerbsWithGivenOneLetter() {

	local response expected
	expected="sleep
smell"

	prepareCompletionVars 1 1 smart_dog.sh "s"
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "$expected" "$response"
}

testCompleteVerbFirstArgument() {

	local response expected
	expected="bill
rex
rintintin
strongheart
snoopy"

	prepareCompletionVars 2 0 smart_dog.sh "call" ""
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "$expected" "$response"
}

testCompleteVerbFirstArgumentStartingWithS() {

	local response expected
	expected="strongheart
snoopy"

	prepareCompletionVars 2 1 smart_dog.sh "call" "s"
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "Callable dogs starting with 's'" "$expected" "$response"
}

testCompleteVerbFirstArgumentStartingWithR() {

	local response expected
	expected="rex
rintintin"

	prepareCompletionVars 2 1 smart_dog.sh "call" "r"
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "Callable dogs starting with 'r'" "$expected" "$response"
}

testCompleteVerbFirstArgumentStartingWithRi() {

	local response expected
	expected="rintintin"

	prepareCompletionVars 2 1 smart_dog.sh "call" "ri"
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "Callable dogs starting with 'ri'" "$expected" "$response"
}

testCompleteVerbNoFirstArgumentStartingWithZ() {

	local response expected
	expected="$NO_REPLY"

	prepareCompletionVars 2 0 smart_dog.sh "call" "z"
	"$completion_function" "${test_common_resources_dir}/smart_dog.sh"
	response="$(getCompReplies)"
	assertEquals "No callable dogs starting with 'z'" "$expected" "$response"
}


runTests

