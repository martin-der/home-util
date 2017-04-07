#!/bin/bash

pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../../.."
popd > /dev/null
test_root_dir="${root_dir}/test"


. "$root_dir/encode.sh"


testURLEncoder() {

	local result
	result="$(encodeUrl "This is some url parameter. Nothing more!")"

	assertEquals "This%20is%20some%20url%20parameter.%20Nothing%20more%21" "$result"
}

testHTMLEncoder() {

	local result
	result="$(encodeHtml <<< "This \"kind of text\" is <b>very</b> important.")"

	assertEquals "This &quot;kind of text&quot; is &lt;b&gt;very&lt;/b&gt; important." "$result"
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

