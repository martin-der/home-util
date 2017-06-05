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
	reset_get_options
}

handleAnimalOption() {
	local o
	o="$1"

	case $o in
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

	while get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix; do
		handleAnimalOption "$option"
	done

	assertEquals "6" "$((OPTIND - 1))"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="1-10000;1;1-Felix;1"

	assertEquals "All animal options" "$expected" "$result"
}

testAllOptionsWithExtraArguments() {

	while get_options "$animal_options" option -a 10000 --beaver --dog --cat Felix and more animals ; do
		handleAnimalOption "$option"
	done

	assertEquals "6" "$((OPTIND - 1))"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="1-10000;1;1-Felix;1"

	assertEquals "All animal options" "$expected" "$result"
}

testOverrideArgumentWithSecondDeclaration() {
	while get_options "$animal_options" option --cat Felix --dog --cat Scratchy; do
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

	while get_options "$animal_options" option --dog --cat ; do
		handleAnimalOption "$option"
	done

	assertEquals "1" "$((OPTIND - 1))"

	local result expected
	result="$(getAnimalOptionsResult)"
	expected="0-;0;0-;1"

	assertEquals "All animal options" "$expected" "$result"
}

runTests
