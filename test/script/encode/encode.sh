#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


. "${src_root_dir}/encode.sh"


testURLEncoder() {

	local result
	result="$(encodeUrl "This is some url parameter. Nothing more!")"

	assertEquals "This%20is%20some%20url%20parameter.%20Nothing%20more%21" "$result"
}

testHTMLEncoder() {

	local result
	result="$(encodeHtml "This \"kind of text\" is <b>very</b> important.")"

	assertEquals "This &quot;kind of text&quot; is &lt;b&gt;very&lt;/b&gt; important." "$result"
}


runTests
