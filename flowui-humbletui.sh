#!/usr/bin/env bash


source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1


     trap "R;exit" 2
    ESC=$( echo -en "\e")
   MOVE(){ echo -en "\e[${1};${2}H";}
  CLEAR(){ echo -en "\ec";}
  CIVIS(){ echo -en "\e[?25l";}
   DRAW(){ echo -en "\e%@\e(0";}
  WRITE(){ echo -en "\e(B";}
   MARK(){ echo -en "\e[7m";}
 UNMARK(){ echo -en "\e[27m";}
      R(){ CLEAR ;stty sane;echo -en "\ec\e[37;44m\e[J";};
           i=0; CLEAR; CIVIS;NULL=/dev/null

__read_key() {
	local key
	read -s -n1 key 2>/dev/null >&2
	if [[ $key = $ESC[A ]]; then echo up; return 0; fi
	if [[ $key = $ESC[B ]]; then echo down; return 0; fi;
	#if [[ $key = $ESC[B ]];then echo down;fi;
	key="$(echo -e "$key" | hexdump -e '16/1 "%02x" "\n"')"
	if [ $key = "0a" ]; then echo enter; return 0; fi;
	[[ $key =~ ^(.*)0a$ ]] && key="${BASH_REMATCH[1]}"
	echo -en "key = $key" >&2
}

__set_fg_color() {
	printf '\e[0;%s8;2;%s;%s;%sm' "3" "$1" "$2" "$3"
	#local bg=4
	#printf "\x1b[${bg};2;${1};${2};${3}m\n"
}
__set_bg_color() {
	printf '\e[0;%s8;2;%s;%s;%sm' "4" "$1" "$2" "$3"
}


__draw_r_at() {
	MOVE $1 $2 ; for ((i=0; i<=$3; i++)); do echo -n "$4"; done
}
__draw_at() {
	MOVE $1 $2 ; echo -en "$3"
}
__draw_label() {
	local x="$2" y="$1" w="$3" f="$4" t="$5"
	local s=0
	[[ "$f" =~ s ]] && s=1
	#[ $s -eq 1 ] && echo $(tput smul/rmul)
	#[ $s -eq 1 ] && echo $(tput smso/rmso)
	#[ $s -eq 1 ] && echo $(tput setf 0,1,2...7)

	[ $s -eq 1 ] && __set_fg_color 0 255 0
	__draw_at $y $(($x+$w-${#t})) "$t"
	[ $s -eq 1 ] && __set_fg_color 255 255 255
	__set_bg_color 0 0 0

}

__draw_input() {
	local x="$2" y="$1" w="$3" f="$4" input="$5" vn="${6:-}"
	local v
	[[ "$input" =~ ^([^:]+):([^:]+)(:([^:]*))?(:(.*))?$ ]] && {
		name="${BASH_REMATCH[1]}"
		type="${BASH_REMATCH[2]}"
		flag="${BASH_REMATCH[4]}"
		validation="${BASH_REMATCH[6]}"
		[[ "$type" =~ \[(.*)\] || "$type" =~ \[(.*)\]\* ]] && {
		 enum="${BASH_REMATCH[1]}"
		 [[ $type == *\* ]] && type="multiple-enum" || type="enum"
		 IFS="|" read -ra values <<< "${enum}"
		 fui_is_input_mandatory "$flag" && [ 0 -eq ${#values[@]} ] && { __print_error "Mandatory enum with no choice '$type'" ; IFS="$previous_IFS" ; return ${FUI_ERROR_INVALID_INPUT_DESC} ; }
		}

		local s=0
		[[ "$f" =~ s ]] && s=1


		v="${!vn}"

		case "$type" in
			string)
				[ $s -eq 1 ] && __set_bg_color 20 60 20 || __set_bg_color 20 20 20
				__draw_r_at $y $x $w " "
				__draw_at $y $x "$v"
				[ $s -eq 1 ] && __draw_at $y $(($x+${#v})) "█"
				__set_bg_color 0 0 0
			;;
			boolean)
				;;
			integer)
				;;
			"multiple-enum")
				;;
			enum)
				;;
			*) __print_error "Unknown type '$type'" ; IFS="$previous_IFS" ; return ${FUI_ERROR_INVALID_COMPONENT_DESC} ;;
		esac
	} || {
	  __draw_at $y $x "BI-$input"
	}
}

__draw_label_input() {
	local x="$2" y="$1" lw="$3" iw="$4" f="$5" label="$6" input="$7" vn="${8:-}"
	__draw_label $y $x "$lw" "$f" "$label"
	__draw_input $y $(($x+$lw+1)) "$iw" "$f" "$input" "$vn"
}

__compute_layout() {
	local components="$1" title="$2" header="$3" footer="$4"
}

__draw() {

	local components="$1" title="$2" header="$3" footer="$4"
	local component component_title inputs input enum values value
	local name label type flag validation
	local x y x_component y_component
	local display_round
	local label_width input_width label_max_width input_max_width component_width
	local s

	local w="$(tput rows)"
	local h="$(tput lines)"
	local input_index component_index

#  IFS="
#" R "$title" "$header" "$footer"
	CLEAR ;stty sane

	tput civis

	x=3
	y=2
	MOVE $y $x ; echo "$title"
	y=$(($y+2))
	[ "x$header" != "x" ] && {
		MOVE $y $x ; echo "$header"
		y=$(($y+2))
	}

	local previous_IFS="$IFS"
	IFS=$'\n'

	__draw_at 0 0 "$(tput cols) / (tput rows)"

	component_index=0
	for component_name in ${components} ; do

		y_component=$y

		component_title="$(fui_get_component_label "$component_name")"
		[ "x$component_title" = x ] && component_title="$component_name"

		component=$(fui_get_component "$component_name" ) || { __print_error "Failed to get component '$component_name'" ; IFS="$previous_IFS" ; return 1 ; }

		label_max_width=0
		input_max_width=0

		for (( display_round = 0; display_round < 2; display_round++ )); do

			[ $display_round -eq 1 ] && {
				s="╔═[ $component_title ]═"
				component_width=$(($label_max_width+1+$input_max_width+5))
				__draw_at $y_component $x "$s"
				__draw_at $y_component $(($x+$component_width-1)) "╗"
				[ $((${#s}+2)) -lt $component_width ] && __draw_r_at $y_component $((x+${#s})) $(($component_width-${#s}-2)) "═"
				__draw_at $((y_component+1)) $x "║"
				__draw_at $((y_component+1)) $(($x+$component_width-1)) "║"
			}


			y=$(($y_component+2))


		input_index=0
		for input in ${component} ; do

		[[ "$input" =~ ^([^:]+):([^:]+)(:([^:]*))?(:(.*))?$ ]] && {
			name="${BASH_REMATCH[1]}"
			type="${BASH_REMATCH[2]}"
			flag="${BASH_REMATCH[4]}"
			validation="${BASH_REMATCH[6]}"
			[[ "$type" =~ \[(.*)\] || "$type" =~ \[(.*)\]\* ]] && {
				enum="${BASH_REMATCH[1]}"
				[[ $type == *\* ]] && type="multiple-enum" || type="enum"
				IFS="|" read -ra values <<< "${enum}"
				fui_is_input_mandatory "$flag" && [ 0 -eq ${#values[@]} ] && { __print_error "Mandatory enum with no choice '$type'" ; IFS="$previous_IFS" ; return ${FUI_ERROR_INVALID_INPUT_DESC} ; }
			}

			label="$(fui_get_input_label "$name" "$component")"
			[ "x$label" = x ] && label="$name"

			label_width="${#label}"
			input_width=15
			[ $display_round -eq 1 ] && {
				local input_flag=
				[ $input_index -eq $selected_input ] && input_flag="${input_flag}s"
				__draw_at $y $x "║"
				#__draw_label $y $((2+$x)) $label_max_width "" "$label"
				__draw_label_input $y $((2+$x)) $label_max_width $input_max_width "$input_flag" "$label" "$input" "$(fui_get_variable_key "$component_name" "$name")"
				__draw_at $y $((x+$component_width-1)) "║"
				} || {
				[ $label_width -gt $label_max_width ] && label_max_width=$label_width
				[ $input_width -gt $input_max_width ] && input_max_width=$input_width
			}
			y=$(($y+1))


		} || {
			__print_error "INVALID_COMPONENT_DESC '$component'"
			IFS="$previous_IFS"
			return ${FUI_ERROR_INVALID_COMPONENT_DESC}

		}
		input_index=$(($input_index+1))
		done
		[ $display_round -eq 1 ] && {
			__draw_at $y $x "╚"
			__draw_r_at $y $((x+1)) $(($component_width-2)) "═"
			__draw_at $y $((x+$component_width-1)) "╝"
		}
		done

		y=$(($y+2))

		component_index=$(($component_index+1))
	done

	[ "x$footer" != "x" ] && {
		MOVE $y $x ; echo "$footer"
		y=$(($y+2))
	}

}

#
# @param 1 components
# @param 2 title
# @param 3 header
# @param 4 footer
#
__fui_run_page_HUMBLETUI() {
	local components="$1" title="$2" header="$3" footer="$4"

	trap "__compute_layout \"$components\" \"$title\" \"$header\" \"$footer\" ;  __draw \"$components\" \"$title\" \"$header\" \"$footer\"" WINCH

	local redraw_needed

	selected_component=0
	selected_input=0

	local previous_IFS="$IFS"
	IFS=$'\n'


	CIVIS


	#while :; do

		__draw "$components" "$title" "$header" "$footer"

		IFS=" "

		page_done=0
		key=

		while [ $page_done -eq 0 ] ; do
			key="$(__read_key)"

			redraw_needed=

			case "$key" in

			up)
				selected_input=$(($selected_input-1))
				redraw_needed=screen
				;;
			down)
				selected_input=$(($selected_input+1))
				#[ selected_input ] &&
				redraw_needed=screen
				;;
			enter)

				#redraw_needed=screen
				break;
				;;

			esac

			[ "x$redraw_needed" = "xscreen" ] && __draw "$components" "$title" "$header" "$footer"
		done

	#done

	IFS="$previous_IFS"
}