#!/bin/bash

source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1



DRY_MODE=0
USE_SUFFIX=0
OUTPUT_FILE=
APPEND_MODIFIED_FILES=0
APPEND_NEW_FILES=0
ALLOW_EMPTY_ARCHIVE=0
SAVE_ARCHIVE_IN_BACKUP_DIR=0
DO_NOT_SAVE_ARCHIVE_IN_BACKUP_DIR=0
PUSH_TO=
QUIET=0
VERBOSE=0

scriptName="${0##*/}"

QUICK_STAMP=$(date +%Y%m%d)

CREATED_ARCHIVES=

printHelpProposal() {
    echo "Type"
    echo "$scriptName -h"
    echo "for help"

}

printUsage() {
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
        Save archive(s) in backup directory.
        This is the default behavior if '-p' is not given.
        Therefore this option is only usefull with '-p'.
	-B
		Don`t save any archive in backup directory.

    -m
        Create archive with modified files.
        Can be combined with '-n'.
    -n
        Create archive with new files.
        Can be combined with '-m'.

    -e
        Allow empty archive creation.
        Handy with '-m' when no file was modified.

    -d
        'drymode' : Simulate, don\'t do actual work

    -q
        quiet
    -v
        verbose

    -h
        Print help and exit
EOF
}

print_arguments_error_and_die() {
	echo "$1" >&2
	printHelpProposal >&2
	exit 1
}

while getopts "so:omnedbBpqvh" option; do
    case "$option" in
        s) USE_SUFFIX=1 ;;
        o) OUTPUT_FILE=$OPTARG ;;
        m) APPEND_MODIFIED_FILES=1 ;;
        n) APPEND_NEW_FILES=1 ;;
        e) ALLOW_EMPTY_ARCHIVE=1 ;;
        d) DRY_MODE=1 ;;
        b) SAVE_ARCHIVE_IN_BACKUP_DIR=1 ;;
        B) DO_NOT_SAVE_ARCHIVE_IN_BACKUP_DIR=1 ;;
        p) PUSH_TO=$OPTARG ;;
        h) printUsage ; exit 3 ;;
        *)
            print_arguments_error_and_die "Unknown option '$option'"
            ;;
    esac
done
shift $((OPTIND - 1))

[ $SAVE_ARCHIVE_IN_BACKUP_DIR -eq 1 -a $DO_NOT_SAVE_ARCHIVE_IN_BACKUP_DIR -eq 1 ] && {
	print_arguments_error_and_die "Options '-b' and '-B' are contradictory"
}
[ $DO_NOT_SAVE_ARCHIVE_IN_BACKUP_DIR -eq 1 -a "x$PUSH_TO" = "x" ] && {
	print_arguments_error_and_die "When asked to no save into backup directory ('-B') a push to option ('-p') must be provided "
}


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

clean_exit() {

	[ $DRY_MODE -eq 0 ] || log_warn "Dry mode : This was a simulation. Nothing has been done"

	exit $1
}

log_debug "Destination directory : ${YELLOW}${TARGET_DIR}${COLOR_RESET}"

[ $DRY_MODE -eq 0 ] || log_info "Dry mode : This is a simulation. Nothing will be done"


EMPTY_ZIP="50 4b 05 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
createEmptyZip() {
	printf "" > "$1"
	while read -d ' ' n ; do printf "\\$(printf "%o" 0x$n)" >> "$1" ; done <<< "$EMPTY_ZIP"
}


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


archiveNameSuffix() {
    local suffix modified git_version
    modified="$1"
    suffix="$QUICK_STAMP"
    git_version="$(git describe --tags 2>/dev/null)" || git_version="$(git rev-parse HEAD)"
    [ "x${1:-}" = "x1" ] && suffix="${suffix}-${git_version}"
    echo "$suffix"
}

makeArchive() {
	local project name pkg_name file_name

	project="$1"
	name="$(basename "$project")"

	pkg_name="${name}-$(archiveNameSuffix)"
	file_name="${TARGET_DIR}/${pkg_name}.tgz"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=tar --prefix="${pkg_name}/" HEAD | gzip > "${file_name}" ) > /dev/null || return 1
	}
	echo "${file_name}"
}

makeArchiveAll() {
	local project name pkg_name file_name

    project="$1"
	name="$(basename "$project")"

	pkg_name="${name}-$(archiveNameSuffix)"
    file_name="${TARGET_DIR}/${pkg_name}.zip"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=zip HEAD > "${file_name}" && zip -r "${file_name}" .git ) > /dev/null || return 1
	}
    echo "${file_name}"
}
makeArchiveModifiedOrNew() {
	local project name pkg_name file_name files

	project="$1"
	shift
	name="$(basename "$project")"

	pkg_name="${name}-$(archiveNameSuffix 1)"

	local list_files_command="git ls-files --exclude-standard"
	[ $APPEND_MODIFIED_FILES -ne 0 ] && list_files_command="$list_files_command -m"
	[ $APPEND_NEW_FILES -ne 0 ] && list_files_command="$list_files_command -o"

	log_info "list_files_command = '$list_files_command'"


    file_name="${TARGET_DIR}/${pkg_name}.zip"
    files="$(${list_files_command})"
    [ "$(echo -n "$files" | wc -l)" -eq 0 ] && {
		[ $ALLOW_EMPTY_ARCHIVE -eq 0 ] && {
			log_error "No file matching criteria('$list_files_command') found : won't create empty archive"
			return 1
		} || {
			log_warn "No file  matching criteria('$list_files_command') found : creating an empty archive"
			[ $DRY_MODE -eq 0 ] && {
				createEmptyZip "$file_name"
			}
		}
	} || {
		[ $DRY_MODE -eq 0 ] && {
			( echo "$files" | (
				zip -@ "$file_name" || {
					log_error "Failed to zip content" >&2
					return 5
				}
			) ) > /dev/null || return 1
		}
	}
    echo "${file_name}"
}



makeAllArchivesFrom() {
	local project archive_all archive
	project=$1

	archive_all=$(makeArchiveAll "$project" ) || {
		clean_exit 2
	}
	log_info "Created all archive '${GREEN}${archive_all}${COLOR_RESET}'"
	CREATED_ARCHIVES="${archive_all}\n"

	archive=$(makeArchive "$project" ) || {
		clean_exit 2
	}
	log_info "Created archive '${GREEN}${archive}${COLOR_RESET}'"
	CREATED_ARCHIVES="${archive}\n"
}
makeArchiveWithModifiedOrNewFrom() {
	local project archive_modified
	project=$1

	archive_modified=$(makeArchiveModifiedOrNew "$project" ) || {
		clean_exit 2
	}
	log_info "Created archive with modified files '${GREEN}${archive_modified}${COLOR_RESET}'"
	CREATED_ARCHIVES="${archive_modified}\n"
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

putAllTo() {
	echo "Send to :"
	echo "'$CREATED_ARCHIVES'"
}


#[ "x$1" == "x." ] && {
#	log_debug "Dealing with current directory..."
#	name=$(basename $(pwd))
#	makeAllArchivesFrom "${name}" || {
#		clean_exit 5
#	}
#	clean_exit 0
#}


while read i ; do

	log_info "Dealing with '${BLUE}$i${COLOR_RESET}'..."
	(
		log_debug "Entering ${YELLOW}${i}${COLOR_RESET}"
		cd "$i" || { 
			log_error "Could not cd into '${YELLOW}$i${COLOR_RESET}'"
			clean_exit 1
		}

		[ $APPEND_MODIFIED_FILES -eq 1 -o $APPEND_NEW_FILES  -eq 1 ] && {
			makeArchiveWithModifiedOrNewFrom "$i"
		} || {
			makeAllArchivesFrom "$i"
		}

	) || {
		log_error "Fatal Error : Unable create archive for '${BLUE}$i${COLOR_RESET}'"
		clean_exit 1
	}
	
done <<< "$projects"

[ "x$PUSH_TO" != "x" ] && {
	putAllTo "$PUSH_TO"
}

clean_exit 0

