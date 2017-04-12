#!/bin/bash

source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1


PUSH_TO_ANDROID=0
REMOTE_DEST=/sdcard/bup/

DRY_MODE=1


[ "x${MDU_BUP_DIRECTORY}" == "x" ] && {
	log_warn "No 'MDU_BUP_DIRECTORY' environment variable defined. defaulting to default value..."
	TARGET_DIR="$HOME"
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




[ "x$1" == "x--send-to-android" ] && { 
	shift
	PUSH_TO_ANDROID=1 
}


# ----------------------------------------------------

# findout projects


[ "x$1" == "x" ] && {
	projects="$(find . -maxdepth 1 -type d -not -path '*/\.*' -not -name '\.' | sed "s#^\\./##")"
} || {
	projects="$1"
}

# ----------------------------------------------------


log_debug "Make archive(s) for the following project(s) : ${projects}"


function makeArchive() {

	NAME="$1"

	QUICK_STAMP=$(date +%Y%m%d)
	PKG_NAME=${NAME}-${QUICK_STAMP}
	FILE_NAME="${TARGET_DIR}/${PKG_NAME}.tgz"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=tar --prefix="${PKG_NAME}/" HEAD | gzip > "${FILE_NAME}" ) > /dev/null || return 1
	}
	echo "${FILE_NAME}"
}

function makeArchiveAll() {

    NAME="$1"

    QUICK_STAMP=$(date +%Y%m%d)
    PKG_NAME=${NAME}-${QUICK_STAMP}
    FILE_NAME="${TARGET_DIR}/${PKG_NAME}.zip"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=zip HEAD > "${FILE_NAME}" && zip -r "${FILE_NAME}" .git ) > /dev/null || return 1
	}
    echo "${FILE_NAME}"
}
function makeArchiveModified() {

    NAME="$1"

    QUICK_STAMP=$(date +%Y%m%d)
    PKG_NAME=${NAME}-${QUICK_STAMP}
    FILE_NAME="${TARGET_DIR}/${PKG_NAME}.m.zip"
	git ls-files -m $@ | zip -@ "$FILE_NAME"
}



function makeAllArchivesFrom() {
	name=$1
	ARCHIVE_ALL=$(makeArchiveAll "$name" ) || { 
		log_error "Could not create \"archive all\" for '$name'"
		clean_exit 2
	}
	log_info "Created all archive '${GREEN}${ARCHIVE_ALL}${COLOR_RESET}'"

	ARCHIVE=$(makeArchive "$name" ) || {
		log_error "Could not create \"archive\" for '$name'"
		clean_exit 2
	}
	log_info "Created archive '${GREEN}${ARCHIVE}${COLOR_RESET}'"
}

[ "x$1" == "x." ] && {
	log_debug "Dealing with current directory..."
	name=$(basename $(pwd))
	makeAllArchivesFrom "${name}" || {
		clean_exit 5
	}
	clean_exit 0
}


echo "$projects" | while read i ; do

	log_info "Dealing with '${BLUE}$i${COLOR_RESET}'...${COLOR_RESET}"
	(
		log_debug "Entering ${YELLOW}$(pwd)/${i}${COLOR_RESET}"
		cd "$i" || { 
			log_error "Could not cd into '${RED}$i${COLOR_RESET}'"
			clean_exit 1 
		}

		makeAllArchivesFrom "$i"

		[ $PUSH_TO_ANDROID -eq 1 ] && {
			adb push "$ARCHIVE" "$REMOTE_DEST" > /dev/null || {
				log_error "Could send archive: adb push '$ARCHIVE' '$REMOTE_DEST'${COLOR_RESET}"
				clean_exit 3
			}
		}
		clean_exit 0
	) || { 
		log_error "Fatal Error : Unable to handle '$i'${COLOR_RESET}"
		clean_exit 1
	}
	
done


