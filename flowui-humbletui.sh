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
   HEAD(){ DRAW
           for each in $(seq 1 13);do
           echo -e "   x                                          x"
           done
           WRITE;MARK;MOVE 1 5
           echo -e "$1";UNMARK;}
           i=0; CLEAR; CIVIS;NULL=/dev/null
   FOOT(){ MARK;MOVE 13 5
           printf "$1";UNMARK;}
  ARROW(){ read -s -n3 key 2>/dev/null >&2
           if [[ $key = $ESC[A ]];then echo up;fi
           if [[ $key = $ESC[B ]];then echo dn;fi;}
     M0(){ MOVE  4 120; echo -en "Login info";}
     M1(){ MOVE  5 120; echo -en "Network";}
     M2(){ MOVE  6 120; echo -en "Disk";}
     M3(){ MOVE  7 120; echo -en "Routing";}
     M4(){ MOVE  8 120; echo -en "Time";}
     M5(){ MOVE  9 120; echo -en "ABOUT  ";}
     M6(){ MOVE 10 120; echo -en "EXIT   ";}
      LM=6
   MENU(){ for each in $(seq 0 $LM);do M${each};done;}
    POS(){ if [[ $cur == up ]];then ((i--));fi
           if [[ $cur == dn ]];then ((i++));fi
           if [[ $i -lt 0   ]];then i=$LM;fi
           if [[ $i -gt $LM ]];then i=0;fi;}
REFRESH(){ after=$((i+1)); before=$((i-1))
           if [[ $before -lt 0  ]];then before=$LM;fi
           if [[ $after -gt $LM ]];then after=0;fi
           if [[ $j -lt $i      ]];then UNMARK;M$before;else UNMARK;M$after;fi
           if [[ $after -eq 0 ]] || [ $before -eq $LM ];then
           UNMARK; M$before; M$after;fi;j=$i;UNMARK;M$before;M$after;}
   INIT(){ R;HEAD "$2";FOOT "$3";MENU;}
     SC(){ REFRESH;MARK;$S;$b;cur=`ARROW`;}
     ES(){ MARK;$e "ENTER = main menu ";$b;read;INIT;}

#  while [[ "$O" != " " ]]; do case $i in
#        0) S=M0;SC;if [[ $cur == "" ]];then R;$e "\n$(w        )\n";ES;fi;;
#        1) S=M1;SC;if [[ $cur == "" ]];then R;$e "\n$(ifconfig )\n";ES;fi;;
#        2) S=M2;SC;if [[ $cur == "" ]];then R;$e "\n$(df -h    )\n";ES;fi;;
#        3) S=M3;SC;if [[ $cur == "" ]];then R;$e "\n$(route -n )\n";ES;fi;;
#        4) S=M4;SC;if [[ $cur == "" ]];then R;$e "\n$(date     )\n";ES;fi;;
#        5) S=M5;SC;if [[ $cur == "" ]];then R;$e "\n$($e by oTo)\n";ES;fi;;
#        6) S=M6;SC;if [[ $cur == "" ]];then R;exit 0;fi;;
# esac;POS;done


__draw() {

	local components="$1" title="$2" header="$3" footer="$4"
	local component component_title inputs input enum values value
	local name label type flag validation
	local x y
	local display_round
	local label_width input_width label_max_width input_max_width

	local w="$(tput rows)"
	local h="$(tput lines)"

	IFS="
" INIT "$title" "$header" "$footer"

	x=10
	y=2
	MOVE $y $x ; echo "$title"
	y=$(($y+2))
	[ "x$header" != "x" ] && {
		MOVE $y $x ; echo "$header"
		y=$(($y+2))
	}

	local previous_IFS="$IFS"
	IFS=$'\n'

	for component_name in ${components} ; do

		component_title="$(fui_get_component_label "$component_name")"
		[ "x$component_title" = x ] && component_title="$component_name"

		MOVE $y $x
		echo -en "--[ $component_name ]--"

		y=$(($y+2))

		component=$(fui_get_component "$component_name" ) || { __print_error "Failed to get component '$component_name'" ; IFS="$previous_IFS" ; return 1 ; }

		label_max_width=0
		input_max_width=0
	    for (( display_round = 0; display_round < 2; display_round++ )); do

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
					input_width=5
					[ $display_round -eq 1 ] && {
						MOVE $y $x
						echo -en "│"
						MOVE $y $((2+$x+$label_max_width-$label_width))
						echo -en "$label :"
						MOVE $y $((2+$x+$label_max_width+2+$input_max_width+1))
						echo -en "│"
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
			done

		done

		y=$(($y+2))

	done
}

#
# @param 1 components
# @param 2 title
# @param 3 header
# @param 4 footer
#
__fui_run_page_HUMBLETUI() {
	local components="$1" title="$2" header="$3" footer="$4"

	local previous_IFS="$IFS"
	IFS=$'\n'

	__draw "$components" "$title" "$header" "$footer"

	IFS=" "


	while [[ "$O" != " " ]]; do case $i in
		0) S=M0;SC;if [[ $cur == "" ]];then R;$e "\n$(w        )\n";ES;fi;;
		1) S=M1;SC;if [[ $cur == "" ]];then R;$e "\n$(ifconfig )\n";ES;fi;;
		2) S=M2;SC;if [[ $cur == "" ]];then R;$e "\n$(df -h    )\n";ES;fi;;
		3) S=M3;SC;if [[ $cur == "" ]];then R;$e "\n$(route -n )\n";ES;fi;;
		4) S=M4;SC;if [[ $cur == "" ]];then R;$e "\n$(date     )\n";ES;fi;;
		5) S=M5;SC;if [[ $cur == "" ]];then R;$e "\n$($e by oTo)\n";ES;fi;;
		6) S=M6;SC;if [[ $cur == "" ]];then R;exit 0;fi;;
	esac;POS;done

	IFS="$previous_IFS"
}