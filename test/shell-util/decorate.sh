#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../.."
popd > /dev/null
test_root_dir="${root_dir}/test"

oneTimeSetUp() {
	. "${root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${root_dir}/resources"
}


testSetThenGetTextDecoration() {
	mdu_setTextDecoration foobar blue_and_shiny
	local foobar_decoration=$(mdu_getTextDecoration foobar)
	assertEquals blue_and_shiny "$foobar_decoration"
}
testSetThenGetThenRemoveTextDecoration() {
	local foobar_decoration
	mdu_setTextDecoration foobar2 blue_and_transparent
	foobar_decoration=$(mdu_getTextDecoration foobar2)
	assertEquals blue_and_transparent "$foobar_decoration"
	mdu_unsetTextDecoration foobar2
	foobar_decoration=$(mdu_getTextDecoration foobar2)
	assertEquals "" "$foobar_decoration"
}

#testSingleDecoration() {
#	mdu_setTextDecoration quote __said_words__
#	local text="Platon said {quote{something useful}}."
#	local decorated="$(decorate "$text" "__-__")"
#	assertEquals "Platon said __said_words__something useful__-__." "$decorated"
#}

#testNestedWithSibblingDecoration() {
#	mdu_setTextDecoration bold __bold__
#	mdu_setTextDecoration red __red__
#	mdu_setTextDecoration green __green__
#	mdu_setTextDecoration yellow __yellow__
#	mdu_setTextDecoration blue __blue__
#	mdu_setTextDecoration underline __underline__
#	local text="Le voisin {yellow{a dit quelque chose que l'{underline{on {bold{peut}} traduire}} par \"{red{c'est de la faute à {blue{Rousseau}} et {green{Voltaire}}... rien de plus}}\"}}. Mais il était saoul."
#	local decorated="$(decorate "$text" "__-__")"
#	assertEquals "Le voisin a dir__-__." "$decorated"
#}



. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

