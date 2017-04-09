#!/bin/bash

pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../../.."
popd > /dev/null
test_root_dir="${root_dir}/test"


oneTimeSetUp() {
	. "$root_dir/flowui.sh"
	__fui_engine=humble-tui
	fui_set_builder shelter_care
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
				"gender:[male]") echo "Male"; return 0 ;;
				"gender:[female]") echo "Female"; return 0 ;;
				"medical-care") echo "Require medical care"; return 0 ;;
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
		component)
			case "$which" in
				animal)
					echo "name:string::[^ ]{2,}"
					echo "species:[dog|cat|mouse|cow|snake]:m"
					echo "gender:[male|female]:m"
					echo "medical-care:boolean"
					echo "find-own-food:boolean"
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

			esac
	esac
	return 0
}

testReceiveAnimal() {
	fui_run_page get_animal
	assertEquals 0 $?
}

[ "x${1:-}" == "xdemo" ] && {
	oneTimeSetUp ;
	fui_run_page get-animal
	fui_list_variables
	exit 0 ;
}


. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ ${__shunit_testsFailed} -gt 0 ] && exit 5 || exit 0

