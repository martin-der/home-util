#!/usr/bin/env bash

source "$1" || exit $?

command_function="$2"

[ "xfunction" = "x$(type -t "$command_function")" ] || {
	echo "Not a function '$command_function'" >&2
	exit 1
}

shift 2

"$command_function" "$@"
