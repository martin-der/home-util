#!/bin/bash

source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1



DRY_MODE=0
USE_SUFFIX=0
OUTPUT_FILE=
MODIFIED_FILES_ONLY=0
PUSH_TO=

scriptName="${0##*/}"

QUICK_STAMP=$(date +%Y%m%d)

function printHelpProposal() {
    echo "Type"
    echo "$scriptName -h"
    echo "for help"

}

function printUsage() {
    cat <<EOF
Synopsis
    $scriptName [-o output_file] [-p use_prefix] [git_directory]
    Execute a command with a time-out.
    Upon time-out expiration SIGTERM (15) is sent to the process. If SIGTERM
    signal is blocked, then the subsequent SIGKILL (9) terminates it.

    -o output_file
        Choose the path and name archive will be created into
        Default value: $PWD-<suffix>.
        See '-s' option for suffix description

    -s
        Append suffix to the archive file name.


	-p destination
        Push file.
        If used, archive save in backup directory is disable
        Use '-a' to
	-b
		Save archive in backup directory.
		This is the default behavior. This option is only usefull

    -m
    	Create archive with modified files only

    -d
        'drymode' : Simulate, don\'t do actual work

    -h
        Print help and exit
EOF
}

while getopts "so:mdph" option; do
    case "$option" in
        s) USE_SUFFIX=1 ;;
        o) OUTPUT_FILE=$OPTARG ;;
        m) MODIFIED_FILES_ONLY=1 ;;
        d) DRY_MODE=1 ;;
        p) PUSH_TO=$OPTARG ;;
        h) printUsage ; exit 3 ;;
        *)
            echo "Unknown option '$option'" >&2
            printHelpProposal >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

[ "x${MDU_BUP_DIRECTORY:-}" == "x" ] && {
	TARGET_DIR="$HOME"
	log_warn "No 'MDU_BUP_DIRECTORY' environment variable defined. defaulting to default value : '$TARGET_DIR'"
} || {
	TARGET_DIR="$MDU_BUP_DIRECTORY"
	[ -d "$TARGET_DIR" ] || {
		log_error "Destination directory 'MDU_BUP_DIRECTORY'='${MDU_BUP_DIRECTORY}' does not exist or is not writable"
		exit 7
	}
}

function clean_exit() {

	[ $DRY_MODE -eq 0 ] || log_warn "Dry mode : This was a simulation. Nothing has been done"

	exit $1
}

log_debug "Destination directory : ${YELLOW}${TARGET_DIR}${COLOR_RESET}"

[ $DRY_MODE -eq 0 ] || log_info "Dry mode : This is a simulation. Nothing will be done"





# ----------------------------------------------------

# findout projects

enumerateProjects() {
	local git_dir
	git_dir="$(git rev-parse --show-toplevel)" && {
		[ "x$(pwd)" = "x${git_dir}" ] && echo "$git_dir"
		return 0
	}
	find . -maxdepth 1 -type d -not -path '*/\.*' -not -name '\.' | sed "s#^\\./##"
}

[ "x$1" == "x" ] && {
	projects="$(enumerateProjects)"
} || {
	projects="$1"
}

# ----------------------------------------------------


log_debug "Make archive(s) for the following project(s) : ${projects}"


function archiveNameSuffix() {
    local suffix modified
    modified="$1"
    suffix="$QUICK_STAMP"
    [ "x${1:-}" = "x1" ] && suffix="${suffix}+$(git describe --tags)"
    echo "$suffix"
}

function makeArchive() {
	local name pkg_name file_name

	name="$1"

	pkg_name="${name}-$(archiveNameSuffix)"
	file_name="${TARGET_DIR}/${pkg_name}.tgz"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=tar --prefix="${pkg_name}/" HEAD | gzip > "${file_name}" ) > /dev/null || return 1
	}
	echo "${file_name}"
}

function makeArchiveAll() {
	local name pkg_name file_name

    name="$1"

	pkg_name="${name}-$(archiveNameSuffix)"
    file_name="${TARGET_DIR}/${pkg_name}.zip"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=zip HEAD > "${file_name}" && zip -r "${file_name}" .git ) > /dev/null || return 1
	}
    echo "${file_name}"
}
function makeArchiveModified() {
	local name pkg_name file_name

	name="$1"
	shift

	pkg_name="${name}-$(archiveNameSuffix 1)"

    file_name="${TARGET_DIR}/${pkg_name}.zip"
	[ $DRY_MODE -eq 0 ] && {
		( git ls-files -m | zip -@ "$file_name" ) > /dev/null || return 1
	}
    echo "${file_name}"
}



function makeAllArchivesFrom() {
	local name archive_all archive
	name=$1

	archive_all=$(makeArchiveAll "$name" ) || {
		log_error "Could not create \"archive all\" for '$name'"
		clean_exit 2
	}
	log_info "Created all archive '${GREEN}${archive_all}${COLOR_RESET}'"

	archive=$(makeArchive "$name" ) || {
		log_error "Could not create \"archive\" for '$name'"
		clean_exit 2
	}
	log_info "Created archive '${GREEN}${archive}${COLOR_RESET}'"
}
function makeArchiveWithModifiedFrom() {
	local name archive_modified
	name=$1

	archive_modified=$(makeArchiveModified "$name" ) || {
		log_error "Could not create \"archive modified\" for '$name'"
		clean_exit 2
	}
	log_info "Created archive with modified files '${GREEN}${archive_modified}${COLOR_RESET}'"
}

putTo() {
	log_error "'Send to' not implemented"
	return 3
	local source target
	source="$1"
	target="$2"
	adb push "$ARCHIVE" "$REMOTE_DEST" > /dev/null || {
		log_error "Could send archive: adb push '$ARCHIVE' '$REMOTE_DEST'${COLOR_RESET}"
		clean_exit 3
	}
}


#[ "x$1" == "x." ] && {
#	log_debug "Dealing with current directory..."
#	name=$(basename $(pwd))
#	makeAllArchivesFrom "${name}" || {
#		clean_exit 5
#	}
#	clean_exit 0
#}


echo "$projects" | while read i ; do

	log_info "Dealing with '${BLUE}$i${COLOR_RESET}'...${COLOR_RESET}"
	(
		log_debug "Entering ${YELLOW}$(pwd)/${i}${COLOR_RESET}"
		cd "$i" || { 
			log_error "Could not cd into '${RED}$i${COLOR_RESET}'"
			clean_exit 1 
		}

		[ $MODIFIED_FILES_ONLY -eq 1 ] && {
			makeArchiveWithModifiedFrom "$i"
		} || {
			makeAllArchivesFrom "$i"
		}


		[ "x$PUSH_TO" != "x" ] && {
			putTo "zzz" "$PUSH_TO"
		}
		clean_exit 0
	) || { 
		log_error "Fatal Error : Unable to handle '${BLUE}$i${COLOR_RESET}'"
		clean_exit 1
	}
	
done


