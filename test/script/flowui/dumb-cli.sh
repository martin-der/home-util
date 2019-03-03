#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"

#exit 0

oneTimeSetUp() {
	. "${src_root_dir}/flowui.sh"
	. "${src_root_dir}/flowui-builder-json.sh"
	__fui_engine=humble-tui
	fui_set_builder shelter_care
	#fui_set_builder from_json_builder
	from_json_builder_set_file "${test_common_resources_dir}/shelter-flowui.json" || exit 1
	fui_set_expresser shelter_care_i18n
}


shelter_care_i18n() {
	case "$1" in
		input)
			case "$2" in
				"name") echo "Name"; return 0 ;;
				"species") echo "Species"; return 0 ;;
				"species:[dog]") echo "Dog"; return 0 ;;
				"species:[cat]") echo "Cat"; return 0 ;;
				"species:[mouse]") echo "Mouse"; return 0 ;;
				"species:[cow]") echo "Cow"; return 0 ;;
				"species:[snake]") echo "Snake"; return 0 ;;
				"gender") echo "Gender"; return 0 ;;
				"predator") echo "Predator"; return 0 ;;
				"gender:[male]") echo "Male"; return 0 ;;
				"gender:[female]") echo "Female"; return 0 ;;
				"medical-care") echo "Require medical care"; return 0 ;;
				"find-own-food") echo "Find own food"; return 0 ;;
				"quantity") echo "Quantity"; return 0 ;;
			esac
			;;
		component)
			case "$2" in
				"animal") echo "Animal"; return 0 ;;
			esac
			;;
		text)
			case "$2" in
				"animal") echo "Animal"; return 0 ;;
			esac
			;;
	esac
	return 1
}
shelter_care() {
	local what="$1" which="$2" part="$3"
	case "$what" in
		type)
			case "$which" in
				name)
					echo 'string:[^ ]{2,}'
					;;
				species)
					echo '[dog|cat|mouse|cow|snake|turtle]'
					;;
				email)
					echo 'string:^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'
					;;
			esac
			;;
		component)
			case "$which" in
				animal)
					echo "name:name"
					echo "species:species:m"
					echo "gender:[male|female]:m"
					echo "medical-care:boolean"
					echo "find-own-food:boolean"
					echo "picture:path"
					echo "predator:species*"
					return 0
					;;
				diet)
					echo "food:string:m:[^\s]+"
					echo "quantity:integer:m:>0"
					return 0
					;;
				habitat)
					echo "place:[rock|desert|bush|forest|pond|river|sea]*:m"
					echo "temperature:integer::<50,>-50"
					return 0
					;;
				care-taker)
					echo "name:name"
					echo "temperature:integer::<50,>-50"
					return 0
					;;
			esac
			;;
		page)
			case "$which" in
				get-animal)
					case "$part" in
						title)
							echo "New animal hosting"
							return 0
							;;
						header)
							echo "Describe the new animal you're about the receive."
							return 0
							;;
						list-components)
							echo "animal"
							return 0
							;;
						navigation)
							[ "x$(fui_get_variable "animal" "find-own-food")" = "x1" ] && echo "=> get-habitat" || echo "=> get-food"
							return 0
					esac
					;;
				get-food)
					case "$part" in
						title)
							echo "Diet"
							return 0
							;;
						header)
							echo "Enter information about a diet."
							return 0
							;;
						footer)
							echo "If you are not sure about the food quantity, pick more than you may need."
							return 0
							;;
						list-components)
							echo "diet"
							return 0
							;;
						navigation)
							echo "=> get-habitat"
							return 0
					esac
					;;
				get-habitat)
					case "$part" in
						title)
							echo "Habitat"
							return 0
							;;
						header)
							echo "Enter information about living place of animal."
							return 0
							;;
						list-components)
							echo "habitat"
							return 0
							;;
					esac
					;;
			esac
			;;
		entrance)
			echo "get-animal"
			;;
	esac
	return 0
}

testReceiveAnimal() {
	fui_run_page get_animal
	assertEquals 0 $?
}

[ "x${1:-}" == "xdemo" ] && {
	src_root_dir="$(dirname "${BASH_SOURCE[0]}")/../../../src"
	test_common_resources_dir="$(dirname "${BASH_SOURCE[0]}")/../../resources/common"
	oneTimeSetUp ;
	fui_set_variable_for_page "get-animal" "animal" "name" "Caroline"
	fui_set_variable_for_page "get-animal" "animal" "picture" "/tmp/"
	fui_set_variable_for_page "get-animal" "animal" "species" "turtle"
	fui_run_first_page
	fui_list_variables
	exit 0 ;
}


runTests
