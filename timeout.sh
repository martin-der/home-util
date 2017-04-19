#!/bin/bash
#
# The Bash shell script executes a command with a time-out.
# Upon time-out expiration SIGTERM (15) is sent to the process. If the signal
# is blocked, then the subsequent SIGKILL (9) terminates it.
#
# Based on the Bash documentation example.

# Hello Chet,
# please find attached a "little easier"  :-)  to comprehend
# time-out example.  If you find it suitable, feel free to include
# anywhere: the very same logic as in the original examples/scripts, a
# little more transparent implementation to my taste.
#
# Dmitry V Golovashkin <Dmitry.Golovashkin@sas.com>

source "$(dirname "$0")/shell-util.sh" 2>/dev/null || source shell-util || exit 1

scriptName="${0##*/}"

declare -i DEFAULT_TIMEOUT=9
declare -i DEFAULT_INTERVAL=1
declare -i DEFAULT_DELAY=1

# Timeout.
declare -i timeout=DEFAULT_TIMEOUT
# Interval between checks if the process is still alive.
declare -i interval=DEFAULT_INTERVAL
# Delay between posting the SIGTERM signal and destroying the process by SIGKILL.
declare -i delay=DEFAULT_DELAY

declare -i quiet=0

function printHelpProposal() {
    echo "Type"
    echo "$scriptName -h"
    echo "for help"

}

function printUsage() {
    cat <<EOF
Synopsis
    $scriptName [-t timeout] [-i interval] [-d delay] command
    Execute a command with a time-out.
    Upon time-out expiration SIGTERM (15) is sent to the process. If SIGTERM
    signal is blocked, then the subsequent SIGKILL (9) terminates it.

    -t timeout
        Number of seconds to wait for command completion.
        Default value: $DEFAULT_TIMEOUT seconds.

    -i interval
        Interval between checks if the process is still alive.
        Positive integer, default value: $DEFAULT_INTERVAL seconds.

    -d delay
        Delay between posting the SIGTERM signal and destroying the
        process by SIGKILL. Default value: $DEFAULT_DELAY seconds.

    -q
        Quiet mode

As of today, Bash does not support floating point arithmetic (sleep does),
therefore all delay/time values must be integers.
EOF
}

CANCEL_STDOUT_FILTER=
CANCEL_STDERR_FILTER=


function parseOptionCancel() {

    local mode
    [[ "$1" =~ ^([^:]+)(:(.*))?$ ]] && {
        mode="${BASH_REMATCH[1]}"
        args="${BASH_REMATCH[3]}"
    } || {
        echo "Error parsing Cancel argument : bad cancel argument '$1'" >&2
        return 1
    }

    case "$mode" in
        stdout)
        	CANCEL_STDOUT_FILTER="$args"
            ;;
        stderr)
        	CANCEL_STDERR_FILTER="$args"
            ;;
        *)
            echo "Error parsing Cancel argument : Unknown mode '$mode'" >&2
            return 1
            ;;
    esac

}

while getopts "t:i:d:c:" option; do
    case "$option" in
        t) timeout=$OPTARG ;;
        i) interval=$OPTARG ;;
        d) delay=$OPTARG ;;
        c)
            parseOptionCancel "$OPTARG" || exit 2
            ;;
        q) quiet=1 ;;
        h) printUsage ; exit 3 ;;
        *)
            echo "Unknown option '$option'" >&2
            printHelpProposal >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

if (($# == 0)); then
    echo "Command missing" >&2
    printHelpProposal >&2
    exit 1
fi
if ((interval <= 0)); then
    echo "Interval must be greater than 0" >&2
    printHelpProposal >&2
    exit 1
fi


(
	TIMEOUT_CANCELED=0
	((t = timeout))

	trap "TIMEOUT_CANCELED=1 ; notify-send 'Timeout Cancele' 'Signal = TERM' " TERM

	while ((t > 0)); do
		sleep ${interval}
		[ $TIMEOUT_CANCELED -ne 0 ] && break
		kill -0 $$ || exit 0
		((t -= interval))
	done

	[ $TIMEOUT_CANCELED -eq 0 ] && {
		kill -s TERM $$ && kill -0 $$ || exit 0
		sleep ${delay}
		kill -s KILL $$
	}

) 2> /dev/null &
timeout_process_id=$!


THIS_STDOUT="/proc/$$/fd/1"
THIS_STDERR="/proc/$$/fd/2"

function process_stdout() {
    tee -a "$THIS_STDOUT" | while read l ; do
        [[ "$l" =~ $CANCEL_STDOUT_FILTER ]] && {
        	#notify-send "Kill" "killing the killer because l='$l'"
			kill -s TERM ${timeout_process_id}
			#return 0
		}
	done
}

function process_stderr() {
	# TODO
	cat >> "$THIS_STDERR"
}

# Run a command and catch stderr, stdout and exit code
# see http://stackoverflow.com/a/18086548
#
#unset t_std t_err t_ret
#eval "$( (echo std; echo err >&2; exit 2 ) 2> >(t_err=$(cat); typeset -p t_err) > >(t_std=$(cat); typeset -p t_std); t_ret=$?; typeset -p t_ret )"
#
#=>
#
#eval "$( ( exec "$@" ) 2> >(t_err=$(cat); typeset -p t_err) > >( process_stdout ); t_ret=$?; typeset -p t_ret )"

if [ "x$CANCEL_STDOUT_FILTER" != x -o "x$CANCEL_STDERR_FILTER" != x ] ; then
	if [ "x$CANCEL_STDOUT_FILTER" == x ] ; then
		log_debug "Run, scanning stderr"
		eval "$( ( exec "$@" ) 2> >( process_stderr 2>/dev/null ) > "$THIS_STDOUT" ); t_ret=$?; typeset -p t_ret )" 2>/dev/null
	elif [ "x$CANCEL_STDERR_FILTER" == x ] ; then
		log_debug "Run, scanning stdout"
		eval "$( ( exec "$@" ) 2> "$THIS_STDERR" > >( process_stdout 2>/dev/null ); t_ret=$?; typeset -p t_ret )" 2>/dev/null
	else
		log_debug "Run, scanning stdout and stderr"
		eval "$( ( exec "$@" ) 2> >( process_stderr 2>/dev/null  ) > >( process_stdout 2>/dev/null  ); t_ret=$?; typeset -p t_ret )" 2>/dev/null
	fi

	exit $t_ret
else
	exec "$@"
fi


