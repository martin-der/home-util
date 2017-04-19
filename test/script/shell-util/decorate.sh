#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	export MDU_NO_COLOR=0
	export MDU_HUMAN_MODE=1
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${src_root_dir}/resources"
}

setupDecorations() {
	mdu_setTextDecoration bold __bold__
	mdu_setTextDecoration red __red__
	mdu_setTextDecoration green __green__
	mdu_setTextDecoration yellow __yellow__
	mdu_setTextDecoration blue __blue__
	mdu_setTextDecoration underline __underline__

	mdu_setTextDecoration bold "$FONT_STYLE_BOLD"
	mdu_setTextDecoration red "$RED"
	mdu_setTextDecoration green "$GREEN"
	mdu_setTextDecoration yellow "$YELLOW"
	mdu_setTextDecoration blue "$BLUE"
	mdu_setTextDecoration underline "$FONT_STYLE_UNDERLINE"
}

testSetThenGetTextDecoration() {
	mdu_setTextDecoration foobar blue_and_shiny
	local foobar_decoration
	foobar_decoration=$(mdu_getTextDecoration foobar)
	assertEquals blue_and_shiny "$foobar_decoration"
}
testSetThenGetThenRemoveTextDecoration() {
	local foobar_decoration

	mdu_setTextDecoration foobar2 blue_and_transparent
	foobar_decoration=$(mdu_getTextDecoration foobar2)
	assertEquals blue_and_transparent "$foobar_decoration"
	mdu_isSetTextDecoration foobar2
	assertEquals 0 $?

	mdu_unsetTextDecoration foobar2
	foobar_decoration=$(mdu_getTextDecoration foobar2)
	assertEquals "" "$foobar_decoration"
	mdu_isSetTextDecoration foobar2
	assertNotSame 0 $?
}

testSingleDecoration() {
	mdu_setTextDecoration quote __said_words__
	local text="Platon said {quote{something useful}}."
	local decorated="$(decorate "$text" "__-__")"
	assertEquals "Platon said __said_words__something useful__-__." "$decorated"
}

ZZtestNestedDecoration() {
	setupDecorations
	mdu_setTextDecoration quote __said_words__
	local text="Platon said {quote{something {green{really}} useful}}."
	local decorated="$(decorate "$text" "__-__")"
	assertEquals "Platon said __said_words__something __green__really__said_words__ useful__-__." "$decorated"
	echo -e "$decorated"
}

testTwoSibblingDecorations() {
	mdu_setTextDecoration quote __said_words__
	local text="Platon said {quote{something useful}} and {quote{something else less useful}}."
	local decorated="$(decorate "$text" "__-__")"
	assertEquals "Platon said __said_words__something useful__-__ and __said_words__something else less useful__-__." "$decorated"
}

#Le voisin {yellow{
#	a dit quelque chose que l'{underline{
#		on {bold{peut}} traduire
#	}} par \"{red{
#		c'est de la faute à {blue{Rousseau}} et {green{Voltaire}}... rien de plus
#	}}\"
#}}. Mais il était saoul.

ZZtestNestedWithSibblingDecoration() {
	setupDecorations
	local text="Le voisin {yellow{a dit quelque chose que l'{underline{on {bold{peut}} traduire}} par \"{red{c'est de la faute à {blue{Rousseau}} et {green{Voltaire}}... rien de plus}}\"}}. Mais il était saoul."
	local decorated="$(decorate "$text" "__-__")"
	echo -e "$decorated"
	assertEquals "Le voisin a dit__-__." "$decorated"
}



runTests
