#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

oneTimeSetUp() {
	source "${src_root_dir}/completion-helper.sh" || exit 1
}


testNormalArgument() {
	local argument core name type
	argument="<foo:bar>"

	_isArgumentRepeatable "$argument"
	assertNotSame 0 $?

	_isArgumentOptionnal "$argument"
	assertNotSame 0 $?

	core="$(_getArgumentCore "$argument")"
	assertEquals "Extract argument core from normal argument" "<foo:bar>" "$core"

	name="$(_getArgumentName "$argument")"
	assertEquals "Extract name from normal argument" "foo" "$name"
	type="$(_getArgumentType "$argument")"
	assertEquals "Extract type from normal argument" "bar" "$type"
}

testOptionalArgument() {
	local argument core name type
	argument="[<foo:bar>]"

	_isArgumentOptionnal "$argument"
	assertEquals 0 $?

	_isArgumentRepeatable "$argument"
	assertNotSame 0 $?

	core="$(_getArgumentCore "$argument")"
	assertEquals "Extract argument core from optional argument" "<foo:bar>" "$core"

	name="$(_getArgumentName "$argument")"
	assertEquals "Extract name from optional argument" "foo" "$name"
	type="$(_getArgumentType "$argument")"
	assertEquals "Extract type from optional argument" "bar" "$type"
}

testRepeatableArgument() {
	local argument core name type
	argument="<foo:bar>..."

	_isArgumentOptionnal "$argument"
	assertNotSame 0 $?

	_isArgumentRepeatable "$argument"
	assertEquals 0 $?

	core="$(_getArgumentCore "$argument")"
	assertEquals "Extract argument core from repeatable argument" "<foo:bar>" "$core"

	name="$(_getArgumentName "$argument")"
	assertEquals "Extract name from repeatable argument" "foo" "$name"
	type="$(_getArgumentType "$argument")"
	assertEquals "Extract type from repeatable argument" "bar" "$type"
}

testOptionalAndRepeatableArgument() {
	local argument core name type
	argument="[<foo:bar>...]"

	_isArgumentOptionnal "$argument"
	assertEquals 0 $?

	_isArgumentRepeatable "$argument"
	assertEquals 0 $?

	core="$(_getArgumentCore "$argument")"
	assertEquals "Extract argument core from optional repeatable argument" "<foo:bar>" "$core"

	name="$(_getArgumentName "$argument")"
	assertEquals "Extract name from optional repeatable argument" "foo" "$name"
	type="$(_getArgumentType "$argument")"
	assertEquals "Extract type from optional repeatable argument" "bar" "$type"
}

#_isArgumentOptionnal() {
#	grep "^\[.*\]$" <<< "$1" >/dev/null
#}
#_isArgumentRepeatable() {
#	grep "^\[.*\.\.\.\]$\|^.*\.\.\.$" <<< "$1" >/dev/null
#}
#_getArgumentFistCouple() {
#	sed "s#^\(<[^>]\+>\).*\$#\1#" <<< "$1"
#}
#_getArgumentFistCoupleFollow() {
#	sed "s#^<[^>]\+>\(.*\)\$#\1#" <<< "$1"
#}
#_getArgumentCore() {
#	sed "s#^\[\([^\.]\+\)\(\.\.\.\)\\?\]\$\|^\([^\.]\+\)\(\.\.\.\)\\?\$#\1\3#" <<< "$1"
#}
#_getArgumentName() {
#	sed "s#^<\([^:]\+\)\(:.\+\)\\?>\$#\1#" <<< "$1"
#}
#_getArgumentType() {
#	sed "s#^<\([^:]\+\):\(.\+\)\\?>\$#\2#" <<< "$1"
#}

runTests
