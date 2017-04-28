#!/bin/bash

source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1



DRY_MODE=0
USE_SUFFIX=0
BACKUP_DIR=
ARCHIVE_FORMAT=
APPEND_SOURCES=0
APPEND_SOURCES_WITH_GIT_HISTORY=0
APPEND_MODIFIED_FILES=0
APPEND_NEW_FILES=0
ALLOW_EMPTY_ARCHIVE=0
SAVE_ARCHIVE_IN_BACKUP_DIR=0
PUSH_TO=
QUIET=0
VERBOSE=0

scriptName="${0##*/}"

QUICK_STAMP=$(date +%Y%m%d)

CREATED_ARCHIVES=
QUALIFIER_ARCHIVE_WITH_SOURCES="source"
QUALIFIER_ARCHIVE_WITH_SOURCES_AND_GIT_HISTORY="source+history"
QUALIFIER_ARCHIVE_WITH_UNCOMMITTED_FILES="desktop"

printHelpProposal() {
    echo "Type"
    echo "$scriptName -h"
    echo "for help"

}

printUsage() {
    cat <<EOF
Synopsis
    $scriptName [options...] [git_directory] -- [included_files...]

    -a archive_type
        Choose the archive format.
        Overrides the format inferred from the suffix of the output file format, if any (see '-f').
        Available formats are ( matching suffix in bracket ) :
            - zip ( .zip )
            - gz  ( .tar.gz, .tgz )
        Note : gz archives are 'tared' first

    -f output_file_format
        Choose the archive\'s format
        TODO : Default value: ???
        See '-s' option for suffix description

    -s
        Append suffix to the archive file name.

	-p destination
        Push file to destination.
        If used, saving of archives in backup directory is disabled
	-b
        Save archive(s) in backup directory.
        This is the default behavior only if '-p' is not given.
        Therefore this option is only useful with '-p'.
	-B directory
		Set the backup directory.
		Implies '-b'

    -h
        Create archive with sources.
    -g
        Create archive with sources and git history.
    -m
        Create archive with modified files ( i.e. uncommitted ).
        Can be combined with '-n'.
    -n
        Create archive with new files ( i.e. untracked ).
        This does not include files excluded from tracking.
        Can be combined with '-m'.

    -e
        Allow empty archive creation.
        Handy with '-m' or '-n' when no file was modified or there is no untracked file.

    -o
    	Overwrite any existing file.
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

while getopts "asf:mnedbB:p:qvh" option; do
	case "$option" in
		a)
			ARCHIVE_FORMAT=$OPTARG
			[ "$ARCHIVE_FORMAT" == "zip" -o "$ARCHIVE_FORMAT" == "gz" ] || print_arguments_error_and_die "Invalid archive format '$ARCHIVE_FORMAT'"
			;;
		s) USE_SUFFIX=1 ;;
		f) ARCHIVE_FORMAT=$OPTARG ;;
		h) APPEND_SOURCES=1 ;;
		g) APPEND_SOURCES_WITH_GIT_HISTORY=1 ;;
		m) APPEND_MODIFIED_FILES=1 ;;
		n) APPEND_NEW_FILES=1 ;;
		e) ALLOW_EMPTY_ARCHIVE=1 ;;
		d) DRY_MODE=1 ;;
		b) SAVE_ARCHIVE_IN_BACKUP_DIR=1 ;;
		B)
			BACKUP_DIR=$OPTARG
			SAVE_ARCHIVE_IN_BACKUP_DIR=1
			[ "x$BACKUP_DIR" = "x" ] && print_arguments_error_and_die "'backup directory' is required with option -B"
			;;
		p)
			PUSH_TO=$OPTARG
			[ "x$PUSH_TO" = "x" ] && print_arguments_error_and_die "'target' is required with option -p"
			;;
		h) printUsage ; exit 3 ;;
		*)
			print_arguments_error_and_die "Unknown option '$option'"
			;;
	esac
done
shift $((OPTIND - 1))

[ $APPEND_SOURCES -eq 0 -a $APPEND_SOURCES_WITH_GIT_HISTORY -eq 0 -a $APPEND_MODIFIED_FILES -eq 0 -a $APPEND_NEW_FILES -eq 0 ] && {
	log_debug "No archive type provided => defaulting to 'source' and 'source with git history'"
	APPEND_SOURCES=1
	APPEND_SOURCES_WITH_GIT_HISTORY=1
}
ONE_TYPE_OF_ARCHIVE=1
[ $(($APPEND_SOURCES + $APPEND_SOURCES_WITH_GIT_HISTORY + $APPEND_MODIFIED_FILES)) -gt 1 ] && ONE_TYPE_OF_ARCHIVE=0
[ $(($APPEND_SOURCES + $APPEND_SOURCES_WITH_GIT_HISTORY + $APPEND_NEW_FILES)) -gt 1 ] && ONE_TYPE_OF_ARCHIVE=0


findOutTargetDir() {
	[ "x$BACKUP_DIR" != "x" ] && { TARGET_DIR="$BACKUP_DIR" ; return 0 ; }
	[ "x${MDU_BUP_DIRECTORY:-}" != "x" ] && { TARGET_DIR="$MDU_BUP_DIRECTORY" ; return 0 ; }
	TARGET_DIR="$HOME"
	log_warn "No 'MDU_BUP_DIRECTORY' environment variable defined and no '-B' option provided. defaulting to default value : '$TARGET_DIR'"
	return 0
}

findOutTargetDir

[ -d "$TARGET_DIR" ] || {
	log_error "Destination directory '${TARGET_DIR}' does not exist or is not writable"
	exit 7
}


clean_on_exit() {
	[ $DRY_MODE -eq 0 ] || log_warn "Dry mode : This was a simulation. Nothing has been done"
}

clean_exit() {
	clean_on_exit
	exit $1
}

log_debug "Destination directory : ${YELLOW}${TARGET_DIR}${COLOR_RESET}"

[ $DRY_MODE -eq 0 ] || log_info "Dry mode : This is a simulation. Nothing will be done"


EMPTY_ZIP="50 4b 05 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 --"
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
    local suffix use_git_id git_version
    use_git_id="${1:-0}"
    suffix="$QUICK_STAMP"
    [ "x${use_git_id}" = "x1" ] && {
	    git_version="$(git describe --tags 2>/dev/null)" || git_version="$(git rev-parse HEAD)"
    	suffix="${suffix}-${git_version}"
    }
    echo "$suffix"
}

getPackageName() {
	local project type use_git_id name
	project="$1"
	type="${2}"
	use_git_id="${3:-0}"
	name="$(basename "$project")"
	[ ${ONE_TYPE_OF_ARCHIVE} -eq 0 ] && name="${name}-${type}"
	echo "${name}-$(archiveNameSuffix "$use_git_id" )"
}

makeArchive() {
	local project pkg_name file_name

	project="$1"

	pkg_name="$(getPackageName "$project" "$QUALIFIER_ARCHIVE_WITH_SOURCES_AND_GIT_HISTORY")"
	file_name="${TARGET_DIR}/${pkg_name}.tgz"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=tar --prefix="${pkg_name}/" HEAD | gzip > "${file_name}" ) > /dev/null || return 1
	}
	echo "${file_name}"
}

makeArchiveAll() {
	local project pkg_name file_name

	project="$1"

	pkg_name="$(getPackageName "$project" "$QUALIFIER_ARCHIVE_WITH_SOURCES_AND_GIT_HISTORY")"
    file_name="${TARGET_DIR}/${pkg_name}.zip"
	[ $DRY_MODE -eq 0 ] && {
		( git archive --format=zip HEAD > "${file_name}" && zip -r "${file_name}" .git ) > /dev/null || return 1
	}
    echo "${file_name}"
}
makeArchiveModifiedOrNew() {
	local project pkg_name file_name files

	project="$1"
	shift

	pkg_name="$(getPackageName "$project" "$QUALIFIER_ARCHIVE_WITH_UNCOMMITTED_FILES")"

	local list_files_command="git ls-files --exclude-standard"
	[ $APPEND_MODIFIED_FILES -ne 0 ] && list_files_command="$list_files_command -m"
	[ $APPEND_NEW_FILES -ne 0 ] && list_files_command="$list_files_command -o"

    file_name="${TARGET_DIR}/${pkg_name}.zip"
    files="$(${list_files_command})"
    [ "$(echo -n "$files" | wc -c)" -eq 0 ] && {
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



makeArchiveSourcesFrom() {
	local project archive_all archive
	project=$1

	archive_all=$(makeArchive "$project" ) || {
		clean_exit 2
	}
	log_info "Created all archive '${GREEN}${archive_all}${COLOR_RESET}'"
	CREATED_ARCHIVES="${archive_all}\n"
}
makeArchiveSourcesWithGitFrom() {
	local project archive_all archive
	project=$1

	archive=$(makeArchiveAll "$project" ) || {
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
	log_info "Created archive with modified or new files '${GREEN}${archive_modified}${COLOR_RESET}'"
	CREATED_ARCHIVES="${archive_modified}\n"
	return 0
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


while read p ; do

	log_info "Dealing with '${BLUE}$p${COLOR_RESET}'..."
	(
		log_debug "Entering ${YELLOW}${p}${COLOR_RESET}"
		cd "$p" || {
			log_error "Could not cd into '${YELLOW}$p${COLOR_RESET}'"
			clean_exit 1
		}

		[ $APPEND_MODIFIED_FILES -eq 1 -o $APPEND_NEW_FILES  -eq 1 ] && {
			log_debug "Creating modified or new files archive"
			makeArchiveWithModifiedOrNewFrom "$p"
		} || true
		[ $APPEND_SOURCES -eq 1 ] && {
			log_debug "Creating sources archive"
			makeArchiveSourcesFrom "$p"
		} || true
		[ $APPEND_SOURCES_WITH_GIT_HISTORY -eq 1 ] && {
			log_debug "Creating sources with git history archive"
			makeArchiveSourcesWithGitFrom "$p"
		} || true

	) || {
		log_error "Fatal Error : Unable create archive for '${BLUE}$p${COLOR_RESET}'"
		clean_exit 1
	}
	
done <<< "$projects"

[ "x$PUSH_TO" != "x" ] && {
	putAllTo "$PUSH_TO"
}

clean_exit 0

