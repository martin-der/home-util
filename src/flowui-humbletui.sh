#!/usr/bin/env bash


source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1

load_source_once sui sh

clean_for_exit() { CLEAR ; stty sane ; }

    ESC="$( echo -en "\e")"
  CLEAR(){ echo -en "\ec";}
  CIVIS(){ echo -en "\e[?25l";}
   DRAW(){ echo -en "\e%@\e(0";}
#   MARK(){ echo -en "\e[7m";}
# UNMARK(){ echo -en "\e[27m";}

FUI_CONFIG_input_min_width=15

__read_key3() {
    stty_state=$(stty -g)
    stty raw isig -echo

    keypress=$(dd count=1 2>/dev/null)
    keycode=$(printf "%s" "$keypress" | xxd -p)

    stty "$stty_state"

    echo -n "$keycode"
}

__read_key2() {
	return 0
	echo ; echo "--------------" ; echo
	echo "before read 1"
	if read -rn 1 -d '' "${T[@]}" "${S[@]}" K; then
		echo "after  read 1"
		KEY[0]=$K

		if [[ $K == $'\e' ]]; then
			if [[ BASH_VERSINFO -ge 4 ]]; then
				T=(-t 0.05)
			else
				T=(-t 1)
			fi

			echo "before read 2"
			if read -rn 1 -d '' "${T[@]}" "${S[@]}" K; then
				echo "after  read 2"
				case "$K" in
				\[)
					KEY[1]=$K

					local -i I=2

					while
						echo "before read C"
						read -rn 1 -d '' "${T[@]}" "${S[@]}" "KEY[$I]" && \
						echo "after  read C"
						[[ ${KEY[I]} != [[:upper:]~] ]]
					do
						(( ++I ))
					done
					;;
				O)
					KEY[1]=$K
					echo "before read D"
					read -rn 1 -d '' "${T[@]}" 'KEY[2]'
					echo "after  read D"
					;;
				[[:print:]]|$'\t'|$'\e')
					KEY[1]=$K
					;;
				*)
					__V1=$K
					;;
				esac
			fi
		fi
	fi

	echo "K = '$(hexdump <<< "$K" | tr '\n' '|')'"
}

keey_l=
__read_key() {
	local ky keey
	keey_l=
	while :; do
		read -s -n1 ky 2>/dev/null >&2
		#if [[ $key = $ESC[A ]]; then echo up; return 0; fi
		#if [[ $key = $ESC[B ]]; then echo down; return 0; fi;
		ky="$(echo -e "$ky" | hexdump -e '16/1 "%02x" "\n"')"
		if [ $ky = "0a" ]; then echo enter; return 0; fi;
		[[ $ky =~ ^(.*)0a\ *$ ]] && ky="${BASH_REMATCH[1]}"
		keey="$keey$ky"
		[[ $keey =~ ^1b ]] || {
			case "$ky" in
				7f) echo "backspace" ; return 0 ;;
				09) echo "tab" ; return 0 ;;
			esac
		}
		[ "${#keey}" -gt 5 ] && break
	done
	keey_l="$keey"
	case $keey in
		1b5b41) echo up; return 0 ;;
		1b5b42) echo down; return 0 ;;
		1b5b43) echo right; return 0 ;;
		1b5b44) echo left; return 0 ;;
		1b5b33) echo delete; return 0 ;;
	esac
}

__move(){ echo -en "\e[${1};${2}H";}

__debug_at() {
	local y=$1
	while IFS="\n" read l; do
		__move $y $2
		echo -en "l"
		y=$((y + 1))
	done <<< "$3"
}

__draw_r_at() {
	__move $1 $2 ; for ((i=0; i<$3; i++)); do echo -n "$4"; done
}
__draw_at() {
	__move $1 $2 ; echo -en "$3"
}
__draw_label() {
	local x="$2" y="$1" w="$3" f="$4" t="$5"
	local l="${#t}" s=0
	[[ "$f" =~ s ]] && s=1
	#[ $s -eq 1 ] && echo $(tput smul/rmul)
	#[ $s -eq 1 ] && echo $(tput smso/rmso)
	#[ $s -eq 1 ] && echo $(tput setf 0,1,2...7)

	sui_set_bg_reset
	[ $s -eq 1 ] && sui_set_fg_color 0 255 0
	[ $l -gt 0 ] && __draw_at $y $(($x+$w-$l)) "$t"
	[ $s -eq 1 ] && sui_set_fg_color 255 255 255
	sui_set_bg_color 0 0 0

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
			fui_is_input_mandatory "$flag" && [ 0 -eq ${#values[@]} ] && { __print_error "Mandatory enum with no choice '$type'" ;  return ${FUI_ERROR_INVALID_INPUT_DESC} ; }
		}

		local s=0
		[[ "$f" =~ s ]] && s=1


		v="${!vn}"

		case "$type" in
			string|name|path)
				[ $s -eq 1 ] && sui_set_bg_color 20 60 20 || sui_set_bg_color 20 20 20
				__draw_r_at $y $x $w " "
				__draw_at $y $x "$v"
				[ $s -eq 1 ] && __draw_at $y $(($x+${#v})) "█"
				sui_set_bg_color 0 0 0
			;;
			boolean)
				;;
			integer)
				;;
			"multiple-enum")
				;;
			enum)
				;;
			*) __print_error "Unknown type '$type'" ;  return ${FUI_ERROR_INVALID_COMPONENT_DESC} ;;
		esac
	}
}



__draw_label_input() {
	local x="$2" y="$1" lw="$3" iw="$4" f="$5" label="$6" input="$7" vn="${8:-}"
	local sep=1
	__draw_label $y $x "$lw" "$f" "$label"
	__draw_input $y $(($x+$lw+$sep)) "$iw" "$f" "$input" "$vn"
}

__global_messages=
__reset_global_messages() {
	__global_messages=
}
__add_global_message() {
	local severity message
	severity="$1"
	message="$2"
	__global_messages="${__global_messages}[$severity] $message
"
}

__draw_messages() {
	sui_set_bg_reset
	local y x messages max_messages max_length
	y="$1"
	x="$2"
	messages="$3"
	max_messages="${4:-4}"
	max_length="${5:-50}"
	local message max_messages_y
	message_y=$y
	max_messages_y=$((message_y+max_messages))
	while [ $message_y -lt $max_messages_y ]; do
		__draw_r_at $message_y $x $max_length ' '
		message_y=$(($message_y + 1))
	done
	message_y=$y
	while IFS="\n" read message; do
		sui_set_fg_color 48 0 250
		__draw_at $message_y $x "${message:0:$max_length}"
		message_y=$(($message_y + 1))
	done <<< "$messages"
	sui_set_fg_color 255 255 255
}
__update_global_messages() {
	__draw_messages 8 50 "$__global_messages" 4
}

_get_component_name() {
	local components="$1" index="$2"
	index=0
	for component_name in ${components} ; do
		echo "$component_name" ; return 0
	done
	return 1
}
_get_component() {
	local components="$1" index="$2"
	local name component
	name="$(_get_component_name "$components" "$index")" || return 1
	component="$(fui_get_component "$name" )" || return 1
	return 0
}


__compute_layout() {
	local components="$1" title="$2" header="$3" footer="$4"
	__viewport_width="$(tput cols)"
	__viewport_height="$(tput lines)"

}

__get_component_content_min_size() {
	local component_index="$1" component_name="$2"
	local component
	local label
	local validation flag type name
	local label_width input_width label_max_width input_max_width height
	height=0
	label_max_width=0
	input_max_width=0

	component=$(fui_get_component "$component_name" ) || { __print_error "Failed to get component '$component_name'" ; }
	while read input ; do

		[[ "$input" =~ ^([^:]+):([^:]+)(:([^:]*))?(:(.*))?$ ]] && {
			name="${BASH_REMATCH[1]}"
			type="${BASH_REMATCH[2]}"
			flag="${BASH_REMATCH[4]}"
			validation="${BASH_REMATCH[6]}"
			[[ "$type" =~ \[(.*)\] || "$type" =~ \[(.*)\]\* ]] && {
				enum="${BASH_REMATCH[1]}"
				[[ $type == *\* ]] && type="multiple-enum" || type="enum"
				IFS="|" read -ra values <<< "${enum}"
				fui_is_input_mandatory "$flag" && [ 0 -eq ${#values[@]} ] && { __print_error "Mandatory enum with no choice '$type'" ;  return ${FUI_ERROR_INVALID_INPUT_DESC} ; }
			}

			label="$(fui_get_input_label "$name" "$component")"
			[ "x$label" = x ] && label="$name"

			label_width="${#label}"
			input_width=${FUI_CONFIG_input_min_width}
			[ $label_width -gt $label_max_width ] && label_max_width=$label_width
			[ $input_width -gt $input_max_width ] && input_max_width=$input_width
			height=$(($height+1))
		}
	done <<< "${component}"
	echo "$(($label_max_width+1+$input_max_width)),$height,$label_max_width,$input_max_width"
}


__draw_selected_cfields() {
	local x="$2" y="$1"
	local components="$3" title="$4" header="$5" footer="$6"
	__draw_cfields_at "$y" "$x" "$selected_input" "$components" "$title" "$header" "$footer"
}
__draw_cfields_at() {
	local x=$2
	local y=$1
	local requested_inputs="$3" component_name="$4" title="$5" header="$6" footer="$7"
	local x_component y_component
	local component_name input

	local label_width input_width

		component=$(fui_get_component "$component_name" ) || { __print_error "Failed to get component '$component_name'" ; return 1 ; }

		__draw_at 3 60 "[R] $component_name => $(__get_component_content_min_size "$component_index" "$component_name")"
		IFS="," read content_width content_height label_width input_width <<< "$(__get_component_content_min_size "$component_index" "$component_name")"

		input_index=0
		while IFS="\n" read input ; do

			 [[ "$input" =~ ^([^:]+):([^:]+)(:([^:]*))?(:(.*))?$ ]] &&
			 {
				name="${BASH_REMATCH[1]}"
				type="${BASH_REMATCH[2]}"
				flag="${BASH_REMATCH[4]}"
				validation="${BASH_REMATCH[6]}"
				[[ "$type" =~ \[(.*)\] || "$type" =~ \[(.*)\]\* ]] && {
					enum="${BASH_REMATCH[1]}"
					[[ $type == *\* ]] && type="multiple-enum" || type="enum"
					IFS="|" read -ra values <<< "${enum}"
					fui_is_input_mandatory "$flag" && [ 0 -eq ${#values[@]} ] && { __print_error "Mandatory enum with no choice '$type'" ; return ${FUI_ERROR_INVALID_INPUT_DESC} ; }
				}

				#[[ $requested_inputs =~ ,?$selected_input,? ]] &&
				{

					label="$(fui_get_input_label "$name" "$component")"
					[ "x$label" = x ] && label="$name"

					local input_flag=
					[ $input_index -eq $selected_input ] && input_flag="${input_flag}s"
					__draw_label_input $y $((2+$x)) $label_width $input_width "$input_flag" "$label" "$input" "$(fui_get_variable_key "$component_name" "$name")"
				}
				input_index=$(($input_index+1))
				y=$(($y+1))
			}
		done <<< "${component}"

}

function __draw_component_border() {
	local x y w h
	local cw ch
	local yh
	local xw
	local title
	local s
	x="$2" ; y="$1" ; w="$3" ; h="$4"
	title="$5"
	#${var:0:1}
	cw=$(($w-4))
	ch=$(($h-3))
	s="╔═[ $title ]"
	# ═($cw;$ch)
	__draw_at $y $x "$s"
	#__draw_at $(($y-1)) $x "($label_width - $input_width)"
	__draw_at $y $(($x+$w-1)) "╗"
	[ $((${#s}+1)) -lt $w ] && __draw_r_at $y $((x+${#s})) $(($w-${#s}-1)) "═"


	y=$(($y + 1))

	yh=$(($y + $ch + 1))
	xw=$((x + $w - 1 ))

	while [ $y -lt $yh ]; do
		__draw_at $y $x "║"
		__draw_at $y $xw "║"
		y=$(($y + 1))
	done

	__draw_at $y $x "╚"
	__draw_r_at $y $((x+1)) $(($w-2)) "═"
	__draw_at $y $((x+$w-1)) "╝"

}

__draw() {

	local components="$1" title="$2" header="$3" footer="$4"
	local component component_title inputs input enum values value
	local name label type flag validation
	local x y x_component y_component
	local display_round
	local label_width input_width component_width
	local s

	local w="$__viewport_width"
	local h="$__viewport_height"
	local input_index component_index

	echo -en "\ec"

	tput civis

	x=$__page_content_x
	y=$__page_content_y

	y=$(($y+2))

	__draw_r_at 0 0 50 ' '
	__draw_at 0 0 "$__viewport_width / $__viewport_height"

	component_index=0
	while IFS="\n" read component_name; do

		y_component=$y

		component_title="$(fui_get_component_label "$component_name")"
		[ "x$component_title" = x ] && component_title="$component_name"

		component=$(fui_get_component "$component_name" ) || { __print_error "Failed to get component '$component_name'" ; return 1 ; }
		__draw_at 2 0 "$component_name : $(echo "$component" | wc -l) element(s)"

		__draw_at 2 60 "[I] $component_index/$component_name => $(__get_component_content_min_size "$component_index" "$component_name")"
		IFS="," read content_width content_height label_width input_width <<< "$(__get_component_content_min_size "$component_index" "$component_name")"

		local hhh="$(wc -l <<< "${component}")"

		__draw_component_border $y $x $(($content_width+4)) $((hhh+3)) $component_title

		y=$(($y+2))

		__draw_cfields_at $y $x "" "$component_name"

		component_index=$(($component_index+1))
	done <<< "${components}"

	[ "x$footer" != "x" ] && {
		__move $y $x ; echo "$footer"
		y=$(($y+2))
	}

}

__get_selected_variable_key() {
	fui_get_variable_key_by_indexes "$1" "$selected_component" "$selected_input"
}

__kex2key() {
	local dec
	case "$1" in
		1b5b41) echo -n up ;;
		1b5b42) echo -n down ;;
		1b5b43) echo -n right ;;
		1b5b44) echo -n left ;;
		7f) echo -n backspace ;;
		08) echo -n 'c:backspace' ;;
		09) echo -n tab ;;
		*)
			dec="$((16#$1))"
			if [ $dec -ge 32 ] ; then
				if [ $dec -le 255 ] ; then
					printf "\x$(printf %x $dec)"
					return 0
				fi
			fi
			echo "hex_$1"
		return 1
	esac
	return 1
}

__handle_key() {
	local components="$1" key="$2"
	local selected_variable selected_value
	local component
	local elements_count

	selected_variable="$(__get_selected_variable_key "$components")" && {
		__draw_at 1 50 "selected '$selected_variable'"
		__draw_at 81 50 "has var"
	} || {
		__draw_at 81 50 "has no var"
	}

	case "$key" in

		up)
			[ $selected_input -gt 0 ] && {
				previous_selected_input=$selected_input
				selected_input=$(($selected_input-1))
				redraw_needed=selected-and-previous
			}
			;;
		down)
			component="$(fui_get_component "$components" $selected_component)"
			elements_count="$(echo "$component" | wc -l)"
			elements_upper=$(($elements_count - 1))
			#$(echo "$component" | wc -l)
			[ $selected_input -lt $elements_upper ] && {
				previous_selected_input=$selected_input
				selected_input=$(($selected_input+1))
				redraw_needed=selected-and-previous
			}
			;;
		enter)
			#redraw_needed=screen
			page_done=1;
			;;
		'c:backspace'|backspace|delete)
			selected_value="$(fui_get_variable_by_key "$selected_variable")"
			[ ${#selected_value} -gt 0 ] && {
				if [ "$key" = 'c:backspace' ] ; then
					selected_value=
				else
					selected_value=${selected_value:0:$((${#selected_value}-1))}
				fi
				fui_set_variable_by_key "$selected_variable" "$selected_value"
				redraw_needed=select-input-value
				__draw_at 2 50 "new-cted '$selected_value'"
			}
			;;
		*)
			[ ${#key} -eq 1 ] && {
				selected_variable="$(__get_selected_variable_key "$components")"
				__draw_at 1 50 "selected '$selected_variable'"
				selected_value="$(fui_get_variable_by_key "$selected_variable")"
				selected_value="${selected_value}${key}"
				fui_set_variable_by_key "$selected_variable" "$selected_value"
				redraw_needed=select-input-value
			}

	esac
}

__exit_warned=1
__handle_sigint() {
	if [ $__exit_warned = 1 ] ; then
		clean_for_exit
		exit
	else
		__add_global_message info "Hit ctrl+c again to exit"
		kill -SIGUSR2 $$
		__exit_warned=1
	fi
}

__fui_run_page_HUMBLETUI() {


	local components="$1" title="$2" header="$3" footer="$4"

	trap "__handle_sigint" 2

	trap "__compute_layout \"$components\" \"$title\" \"$header\" \"$footer\" ;  __draw \"$components\" \"$title\" \"$header\" \"$footer\"" WINCH
	trap "__update_global_messages" USR2

	__compute_layout "$components" "$title" "$header" "$footer"

	local redraw_needed default_action
	local key

	local inputs_x inputs_y

	selected_component=0
	selected_input=0
	previous_selected_input=-1

	__page_content_x=3
	__page_content_y=2


	CIVIS

	redraw_needed=
	default_action=0

	__draw "$components" "$title" "$header" "$footer"

	IFS=" "

	page_done=0
	key=

	inputs_x=$__page_content_x
	inputs_y=$(($__page_content_y + 4))

	while [ $page_done -eq 0 ] ; do
		fui__reset_errors
		key="$(__read_key3)"
		key="$(__kex2key "$key")"

		redraw_needed=

		__handle_key "$components" "$key"

		[ "x$redraw_needed" = "xscreen" ] && __draw "$components" "$title" "$header" "$footer"
		[ "x$redraw_needed" = "xselect-input-value" ] && __draw_selected_cfields $inputs_y $inputs_x "$components" "$title" "$header" "$footer"
		[ "x$redraw_needed" = "xselected-and-previous" ] && __draw_cfields_at $inputs_y $inputs_x "$previous_selected_input,$selected_input" "$components" "$title" "$header" "$footer"


		sui_set_bg_reset

		sui_set_fg_color 80 128 255
		__draw_r_at 10 60 50 ' '
		__draw_at 10 60 "component:$selected_component input:$selected_input"
		__draw_r_at 11 60 50 ' '
		__draw_at 11 60 "key = '$key'"
		__draw_r_at 12 60 50 ' '
		__draw_at 12 60 "keey_l = '$keey_l'"
		__draw_r_at 13 60 50 ' '
		__draw_at 13 60 "components:$components"


		local errors error_y
		error_y=15
		while [ $error_y -lt 70 ]; do
			__draw_r_at $error_y 80 50 ' '
			error_y=$(($error_y + 1))
		done
		sui_set_fg_color 255 0 0
		errors="$(fui__get_errors)"
		error_y=15
		while IFS="\n" read error_line; do
			__draw_at $error_y 80 "${error_line:0:50}"
			error_y=$(($error_y + 1))
		done <<< "$(echo "$errors")"
		sui_set_fg_color 255 255 255

	done
}