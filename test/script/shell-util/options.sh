#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


oneTimeSetUp() {
	. "${src_root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${src_root_dir}/resources"

	animal_options="a|ant:,b|beaver,cat:,dog"
}

setUp() {
	has_ant=0
	ant_count=
	has_beaver=0
	has_cat=0
	cat_name=
	has_dog=0
}

tearDown() {
	mdu_get_options_reset
}

handleAnimalOption() {
	local o
	o="$1"

	case ${o} in
		a|ant)
			has_ant=1
			ant_count="${OPTARG}"
			;;
		b|beaver) has_beaver=1 ;;
		cat)
			has_cat=1
			cat_name="${OPTARG}"
			;;
		dog) has_dog=1 ;;
	esac
	#echo "option='$option'" >&2
	#echo "OPTIND='$OPTIND' OPTARG='${OPTARG:-}'" >&2
}
getAnimalOptionsResult() {
	echo "${has_ant}-${ant_count};${has_beaver};${has_cat}-${cat_name};${has_dog}"
}

testAllOptions() {

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix
	__assertLastCommandSucceeded $?
	assertEquals "a" "$option"
	assertEquals "10000" "$OPTARG"
	assertEquals "2" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix
	__assertLastCommandSucceeded $?
	assertEquals "b" "$option"
	assertVariableUnbound "OPTARG is unbound" "OPTARG"
	assertEquals "3" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix
	__assertLastCommandSucceeded $?
	assertEquals "dog" "$option"
	assertVariableUnbound "OPTARG is unbound" "OPTARG"
	assertEquals "4" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix
	__assertLastCommandSucceeded $?
	assertEquals "cat" "$option"
	assertEquals "Felix" "$OPTARG"
	assertEquals "6" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="1-10000;1;1-Felix;1"

	assertEquals "All animal options" "$expected" "$result"
}


testAllOptionsWithExtraArguments() {

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix and more animals
	__assertLastCommandSucceeded $?
	assertEquals "a" "$option"
	assertEquals "10000" "$OPTARG"
	assertEquals "2" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix and more animals
	__assertLastCommandSucceeded $?
	assertEquals "b" "$option"
	assertVariableUnbound "OPTARG is unbound" "OPTARG"
	assertEquals "3" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix and more animals
	__assertLastCommandSucceeded $?
	assertEquals "dog" "$option"
	assertVariableUnbound "OPTARG is unbound" "OPTARG"
	assertEquals "4" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix and more animals
	__assertLastCommandSucceeded $?
	assertEquals "cat" "$option"
	assertEquals "Felix" "$OPTARG"
	assertEquals "6" "$((OPTIND - 1))"
	handleAnimalOption "$option"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="1-10000;1;1-Felix;1"

	assertEquals "All animal options" "$expected" "$result"

	#shift 6

	##assertEquals "All animal extra options" "Felix and more animals" "ee  $@"
}

testOverrideArgumentWithSecondDeclaration() {
	while get_options "$animal_options" option --cat Felix --dog --cat Scratchy ; do
		handleAnimalOption "$option"
	done

	assertEquals "5" "$((OPTIND - 1))"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="0-;0;1-Scratchy;1"

	assertEquals "Overridden cat name option" "$expected" "$result"
}

testOverrideArgumentWithSecondDeclarationWithExtraArguments() {
	while get_options "$animal_options" option --cat Felix --dog --cat Scratchy and more animals; do
		handleAnimalOption "$option"
	done

	assertEquals "5" "$((OPTIND - 1))"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="0-;0;1-Scratchy;1"

	assertEquals "Overridden cat name option" "$expected" "$result"
}

testOptionParameterMissing() {

	while get_options "$animal_options" option --dog --cat 2>/dev/null ; do
		handleAnimalOption "$option"
	done

	assertEquals "1" "$((OPTIND - 1))"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="0-;0;0-;1"

	assertEquals "All animal options" "$expected" "$result"
}

assertVariableUnbound() {
	local unbound_return
	local var_name

	if [ $# -gt 1 ] ; then
		var_name="$2"
	else
		var_name="$1"
	fi

	eval "if [ -z \"\${$var_name+x}\" ] ; then unbound_return=0 ; else unbound_return=1 ; fi" >&2

	if [ $# -gt 1 ] ; then
		assertTrue "$1" "[ 0 -eq $unbound_return ]"
	else
		assertTrue "[ 0 -eq $unbound_return ]"
	fi

}

runTests
