#!/usr/bin/env bash

source "$(readlink "$(dirname "$0")/shell-util.sh")" 2>/dev/null \
|| source "$(dirname "$0")/shell-util.sh" 2>/dev/null \
|| source shell-util || exit 1



SIMULATION_MODE=0
USE_SUFFIX=0
BACKUP_DIR=
ARCHIVE_FORMAT=
APPEND_SOURCES=0
APPEND_SOURCES_WITH_GIT_HISTORY=0
APPEND_MODIFIED_FILES=0
APPEND_NEW_FILES=0
ARCHIVE_PARENT_DIRECTORY_PREFIX=
ARCHIVE_PARENT_DIRECTORY_PREFIX_FORCED=0
OUTPUT_FILE_FORMAT=
ALLOW_EMPTY_ARCHIVE=0
EXPLICIT_SAVE_ARCHIVE_IN_BACKUP_DIR=0
PUSH_TO=
FORCE_OVERWRITE=0
QUIET=0
VERBOSE=0

scriptName="${0##*/}"

QUALIFIER_ARCHIVE_WITH_SOURCES="source"
QUALIFIER_ARCHIVE_WITH_SOURCES_AND_GIT_HISTORY="source+history"
QUALIFIER_ARCHIVE_WITH_UNTRACKED_FILES="desktop"


ERROR_PROJECT_DIRECTORY_NOT_ACCESSIBLE=29
ERROR_NO_GIT_PROJECT_FOUND=30
ERROR_DESTINATION_DIRECTORY_NOT_WRITABLE=31
ERROR_WOULD_OVERWRITE=32
ERROR_REFUSE_EMPTY_ARCHIVE=33
ERROR_ARCHIVE_CREATION_FAILURE=34
ERROR_COMPRESSION_FAILURE=35
ERROR_BUILDING_INTERMEDIATE_DATA=36
ERROR_ARCHIVE_FROM_GIT_FAILURE=37
ERROR_UNKNOWN_DESTINATION_EXTENSION=38
ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION=40
ERROR_MISCELLANEOUS=50

printHelpProposal() {
    echo "Type"
    echo "$scriptName -h"
    echo "for help"

}

printUsage() {
    cat <<EOF
Synopsis
    $scriptName [options...] [git_directory] -- [included_files...]

Description
    Creates up to three type of archives.
    * create an archive with all files at current revision.
    * create an archive with all files at current revision and the git history.
    * create an archive with all modified files at current revision and the git history.

Options

    -a archive_type
        Choose the archive format.
        Overrides the format inferred from the suffix of the output file format, if any (see '-f').
        Available formats are ( matching suffixes in bracket ) :
            - zip   ( .zip )
            - tar   ( .tar )
            - gz    ( .tar.gz, .tgz )
            - bzip2 ( .tar.bz2, .tbz2 )
        Note : gz, bz2 archives are 'tared' first

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

    -k
        Create archive with sources.
    -g
        Create archive with sources and git history.
    -m
        Create archive with modified files ( i.e. uncommitted ).
        If combined with '-n' then all files will end in the same archive.
    -n
        Create archive with new files ( i.e. untracked ).
        This does not include files excluded from tracking.
        If combined with '-m' then all files will end in the same archive.

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

while getopts "a:sp:f:kgmneodbB:P:qvh" option; do
	case "$option" in
		a)
			[ "$OPTARG" == "zip" -o "$OPTARG" == "gz" ] || print_arguments_error_and_die "Invalid archive format '$OPTARG'"
			ARCHIVE_FORMAT=$OPTARG
			;;
		s) USE_SUFFIX=1 ;;
		p)
			ARCHIVE_PARENT_DIRECTORY_PREFIX=$OPTARG
			ARCHIVE_PARENT_DIRECTORY_PREFIX_FORCED=1
			;;
		f)
			OUTPUT_FILE_FORMAT=$OPTARG
			;;
		#f) ARCHIVE_FORMAT=$OPTARG ;;
		k) APPEND_SOURCES=1 ;;
		g) APPEND_SOURCES_WITH_GIT_HISTORY=1 ;;
		m) APPEND_MODIFIED_FILES=1 ;;
		n) APPEND_NEW_FILES=1 ;;
		e) ALLOW_EMPTY_ARCHIVE=1 ;;
		o) FORCE_OVERWRITE=1 ;;
		d) SIMULATION_MODE=1 ;;
		b) EXPLICIT_SAVE_ARCHIVE_IN_BACKUP_DIR=1 ;;
		B)
			BACKUP_DIR=$OPTARG
			EXPLICIT_SAVE_ARCHIVE_IN_BACKUP_DIR=1
			[ "x$BACKUP_DIR" = "x" ] && print_arguments_error_and_die "'backup directory' is required with option -B"
			;;
		P)
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

SAVE_ARCHIVE_IN_BACKUP_DIR=1
[ "x$PUSH_TO" != "x" -a $EXPLICIT_SAVE_ARCHIVE_IN_BACKUP_DIR -eq 0 ] && SAVE_ARCHIVE_IN_BACKUP_DIR=0
TMP_DIRECTORY=

QUICK_STAMP=$(date +%Y%m%d)
CREATED_ARCHIVE=
CREATED_ARCHIVES=


clean_on_exit() {
	[ $SIMULATION_MODE -eq 0 ] || log_warn "Dry mode : This was a simulation. Nothing has been done"
	[ "x$TMP_DIRECTORY" != "x" ] && {
		log_debug "Removing working dir '$TMP_DIRECTORY'"
		rm -rf "$TMP_DIRECTORY"
	}
}

trap clean_on_exit EXIT INT TERM

[ $SAVE_ARCHIVE_IN_BACKUP_DIR -eq 0 ] && {
	TMP_DIRECTORY=`mktemp -d -t mkGitarchive-bup.XXXXXXXXXX` || exit $ERROR_MISCELLANEOUS
}

findOutTargetDir() {
	[ $SAVE_ARCHIVE_IN_BACKUP_DIR -eq 0 ] && {

		return 0
	}

	[ "x$BACKUP_DIR" != "x" ] && { TARGET_DIR="$BACKUP_DIR" ; return 0 ; }
	[ "x${MDU_BUP_DIRECTORY:-}" != "x" ] && { TARGET_DIR="$MDU_BUP_DIRECTORY" ; return 0 ; }
	TARGET_DIR="$HOME"
	log_warn "No 'MDU_BUP_DIRECTORY' environment variable defined and no '-B' option provided. defaulting to default value : '$TARGET_DIR'"
	return 0
}

log_debug "BACKUP_DIR='$BACKUP_DIR'"
log_debug "SAVE_ARCHIVE_IN_BACKUP_DIR='$SAVE_ARCHIVE_IN_BACKUP_DIR'"
log_debug "TARGET_DIR='$TARGET_DIR'"
findOutTargetDir

[ -d "$TARGET_DIR" ] || {
	log_error "Destination directory '${TARGET_DIR}' does not exist or is not writable"
	exit $ERROR_DESTINATION_DIRECTORY_NOT_WRITABLE
}

log_debug "Destination directory : ${YELLOW}${TARGET_DIR}${COLOR_RESET}"

[ $SIMULATION_MODE -eq 0 ] || log_info "Dry mode : This is a simulation. Nothing will be done"


EMPTY_ZIP="50 4b 05 06 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 --"
createEmptyZip() {
	printf "" > "$1"
	while read -d ' ' n ; do printf "\\$(printf "%o" 0x$n)" >> "$1" ; done <<< "$EMPTY_ZIP"
}


checkFileOrDieWouldOverwrite() {
	local file
	file="$1"
	[ -e "$file" ] && {
		[ $FORCE_OVERWRITE -eq 0 ] && {
			log_error "File '$file' exists and overwrite is not allowed"
			exit $ERROR_WOULD_OVERWRITE
		}
		log_info "Overwriting ${YELLOW}'${file}'${COLOR_RESET}"
	}
	return 0
}

# ----------------------------------------------------

# findout projects

# 0 => git root dir
# 1 => git dir but not root dir
# 2 => not a git dir
isGitRootDir() {
	local git_dir project
	git_dir="$(git rev-parse --show-toplevel)" || return 2

	git_dir="$(realpath "$git_dir")"
	project="$(realpath "$(pwd)")"
	[ "${git_dir}" = "${project}" ] && {
		return 0
	}
	return 1
}

enumerateProjects() {
	local found_projects
	isGitRootDir && {
		echo "$(pwd)"
		return 0
	}
	found_projects=0
	 while read p ; do
		( cd "$p" && isGitRootDir ) && {
			echo "$p" | sed "s#^\\./##"
			found_projects=$(($found_projects + 1))
		}
	done <<< "$(find . -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -not -name '\.')"
	[ found_projects -gt 0 ] && return 0

	return 1
}

[ "x$1" == "x" ] && {
	projects="$(enumerateProjects)" || {
		log_error "Not git project(s) found from ${BLUE}'$(pwd)'${COLOR_RESET}"
		exit ${ERROR_NO_GIT_PROJECT_FOUND}
	}
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
	use_git_id="${3:-1}"
	name="$(basename "$project")"
	[ ${ONE_TYPE_OF_ARCHIVE} -eq 0 ] && name="${name}-${type}"
	echo "${name}-$(archiveNameSuffix "$use_git_id" )"
}

getPackageType() {
	local destination
	destination="$1"
	[ "x$ARCHIVE_FORMAT" != "x" ] && {
		echo "$ARCHIVE_FORMAT"
		return 0
	}
	local filename dir base ext
	filename="${destination##*/}"
    #dir="${destination:0:${#destination} - ${#filename}}"
    base="${filename%.[^.]*}"
    ext="${filename:${#base} + 1}"
    if [[ -z "$base" && -n "$ext" ]]; then
    	# If we have an extension and no base, it's really the base
        base=".$ext"
        ext=""
    fi
    case "$ext" in
    	"zip") echo "zip" ; return 0 ;;
    	"tar.gz"|"tgz") echo "gz" ; return 0 ;;
    esac
    log_error "Could not infer archive type from filename '$filename'."
    return ${ERROR_UNKNOWN_DESTINATION_EXTENSION}
}

# @param 1 parent source directory
# @param 2 source directory name
# @param 3 destination file
# @param 4 archive type
createArchiveFromDirectory() {
	local parent_path dir_name destination_file format
	parent_path="$1"
	dir_name="$2"
	destination_file="$3"
	format="$4"

	pushd "$parent_path" || return ${ERROR_BUILDING_INTERMEDIATE_DATA}
	case "$format" in
		"zip")
			zip -rq "$destination_file" "$dir_name" || {
				popd
				log_error "Failed to zip content"
				return ${ERROR_COMPRESSION_FAILURE}
			}
			;;
		"tar")
			(
				tar cf "$dir_name" || {
					popd
					log_error "Failed to tar content"
					return ${ERROR_COMPRESSION_FAILURE}
				}
			) > "$destination_file"
			;;
		"gz"|"bz2")
			case "$format" in
				"gz")
					compress_command=gzip
					;;
				"bzip2")
					compress_command=bzip2
					;;
				*)
					popd
					log_error "Command for piped compression with '$format' format is unknown"
					return ${ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION}
			esac
			(
				tar cf "$dir_name" || {
					popd
					log_error "Failed to tar content"
					return ${ERROR_COMPRESSION_FAILURE}
				}
			) | ${compress_command} > "$destination_file"
			;;
		*)
			popd
			log_error "Unsupported archive type '$format'"
			return ${ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION}
	esac
	popd
}

# @param 1 source if '-' then use files list from stdin else git revision
# @param 2 destination
# @param 3 archive directory prefix
# @param 4 add '.git' directory
createArchive() {
	local source destination prefix add_git format compress_command
	source="$1"
	destination="$2"
	prefix="$3"
	add_git="${4:-0}"


	format="$(getPackageType "$destination")" || return $?
	#log_warn "Archive format is : '$format'"

	if [ "$source" = "-" ] ; then
		local all_files
		all_files="$(cat)"
		if [ "x${prefix}" != x ] ; then
			(
				local temp_dest relative_dir_dest temp_dest_prefix
				temp_dest=`mktemp -d -t mkGitarchive-fp.XXXXXXXXXX` || return ${ERROR_MISCELLANEOUS}
				trap "rm -rf \"${temp_dest}\"" EXIT INT TERM
				temp_dest_prefix="${temp_dest}/${prefix}"
				while read f ; do
					relative_dir_dest="${temp_dest_prefix}/$(dirname "$f")"
					mkdir -p "$relative_dir_dest" || return ${ERROR_BUILDING_INTERMEDIATE_DATA}
					cp "$f" "${temp_dest_prefix}/${f}" || return ${ERROR_BUILDING_INTERMEDIATE_DATA}
				done <<< "$all_files"
				createArchiveFromDirectory "$temp_dest" "$prefix" "$destination" "$format" || return $?
			) || return $?
		else
			case "$format" in
				"zip")
					zip -@ "$destination" || {
						log_error "Failed to zip content"
						return ${ERROR_COMPRESSION_FAILURE}
					}
					;;
				"gz"|"bz2")
					case "$format" in
						"gz")
							compress_command=gzip
							;;
						"bzip2")
							compress_command=bzip2
							;;
						*)
							log_error "Command for piped compression with '$format' format is unknown"
							return ${ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION}
					esac
					(
						tar c -T - || {
							log_error "Failed to tar content"
							return ${ERROR_COMPRESSION_FAILURE}
						}
					) | ${compress_command} > "$destination"
					;;
				*)
					log_error "Command for compressing files list from stdin with '$format' format is unknown"
					return ${ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION}
			esac
		fi
	else
		if [ "x${prefix}" != x ] ; then
			(
				local temp_dest relative_dir_dest temp_dest_prefix
				temp_dest=`mktemp -d -t mkGitarchive-fp.XXXXXXXXXX` || return ${ERROR_MISCELLANEOUS}
				trap "rm -rf \"${temp_dest}\"" EXIT INT TERM
				temp_dest_prefix="${temp_dest}/${prefix}"
				mkdir -p "$temp_dest_prefix" || return ${ERROR_BUILDING_INTERMEDIATE_DATA}
				( git archive --format=tar "$source" | tar xf - -C "$temp_dest_prefix" ) || return ${ERROR_ARCHIVE_CREATION_FAILURE}
				[ $add_git -eq 1 ] && {
					cp -r ".git" "${temp_dest}/${prefix}/.git" > /dev/null || {
						log_error "Failed to add '.git' to zip archive"
						return ${ERROR_BUILDING_INTERMEDIATE_DATA}
					}
				}
				createArchiveFromDirectory "$temp_dest" "$prefix" "$destination" "$format" || return $?
			) || return $?
		else
			case "$format" in
				"zip")
					git archive --format=zip "$source" > "$destination" || {
						log_error "Failed to create git archive"
						return ${ERROR_ARCHIVE_FROM_GIT_FAILURE}
					}
					[ $add_git -eq 1 ] && {
						zip -r "${destination}" .git > /dev/null || {
							log_error "Failed to add '.git' to zip archive"
							return ${ERROR_COMPRESSION_FAILURE}
						}
					}
					;;
				"gz"|"bz2")
					case "$format" in
						"gz")
							compress_command=gzip
							;;
						"bz2")
							compress_command=bzip2
							;;
						*)
							log_error "Command for piped compression with '$format' format is unknown"
							return ${ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION}
					esac
					(
						local temp_dest
						[ $add_git -eq 1 ] && {
							temp_dest="${destination}.$$.temp"
							trap "rm -f \"${destination}.$$.temp\"" EXIT INT TERM
						}
						{
							if [ $add_git -eq 1 ] ; then
								git archive --format=tar "$1" > "$temp_dest"
							else
								git archive --format=zip "$1"
							fi
						} || {
							log_error "Failed to create tar archive"
							return ${ERROR_ARCHIVE_FROM_GIT_FAILURE}
						}
						[ $add_git -eq 1 ] && {
							tar -fr "${temp_dest}" .git > /dev/null || {
								log_error "Failed to add '.git' to tar archive"
								return ${ERROR_COMPRESSION_FAILURE}
							}
							cat "$temp_dest" || {
								log_error "Failed to cat tar archive with '.git'"
								return ${ERROR_COMPRESSION_FAILURE}
							}
						}
					) | ${compress_command} > "$destination" || {
						log_error "Failed to compress tar archive"
						return ${ERROR_COMPRESSION_FAILURE}
					}
					;;
				*)
					log_error "Format '$format' is unknown for the git create archive command"
					return ${ERROR_INTERNAL_MISSING_COMPRESS_INFORMATION}
					;;
			esac
		fi
	fi
}

makeArchive() {
	local project pkg_name file_name

	project="$1"

	pkg_name="$(getPackageName "$project" "$QUALIFIER_ARCHIVE_WITH_SOURCES_AND_GIT_HISTORY")"
	file_name="${TARGET_DIR}/${pkg_name}.tgz"
	checkFileOrDieWouldOverwrite "$file_name"
	createArchive "HEAD" "$file_name" "$(basename "$project")" 0 || return $?
	CREATED_ARCHIVE="${file_name}"
}

makeArchiveAll() {
	local project pkg_name file_name

	project="$1"

	pkg_name="$(getPackageName "$project" "$QUALIFIER_ARCHIVE_WITH_SOURCES")"
    file_name="${TARGET_DIR}/${pkg_name}.zip"
	checkFileOrDieWouldOverwrite "$file_name"
	createArchive "HEAD" "$file_name" "$(basename "$project")" 1 || return $?
	CREATED_ARCHIVE="${file_name}"
}
makeArchiveModifiedOrNew() {
	local project pkg_name file_name files

	project="$1"
	shift

	pkg_name="$(getPackageName "$project" "$QUALIFIER_ARCHIVE_WITH_UNTRACKED_FILES")"

	local list_files_command="git ls-files --exclude-standard"
	[ $APPEND_MODIFIED_FILES -ne 0 ] && list_files_command="$list_files_command -m"
	[ $APPEND_NEW_FILES -ne 0 ] && list_files_command="$list_files_command -o"

    file_name="${TARGET_DIR}/${pkg_name}.zip"
	checkFileOrDieWouldOverwrite "$file_name"
    files="$(${list_files_command})"
	[ "$(echo -n "$files" | wc -c)" -eq 0 ] && {
		[ $ALLOW_EMPTY_ARCHIVE -eq 0 ] && {
			log_error "No file matching criteria found : won't create empty archive"
			return $ERROR_REFUSE_EMPTY_ARCHIVE
		} || {
			log_warn "No file  matching criteria found : creating an empty archive"
			[ $SIMULATION_MODE -eq 0 ] && {
				createEmptyZip "$file_name"
			}
		}
	} || {
		echo -n "$files" | createArchive - "$file_name" "$(basename "$project")" 0 || return $?
	}
	CREATED_ARCHIVE="${file_name}"
}



makeArchiveSourcesFrom() {
	local project archive
	project=$1

	makeArchive "$project" || {
		exit 2
	}
	archive="${CREATED_ARCHIVE}"
	log_info "Created archive '${GREEN}${archive}${COLOR_RESET}'"
	CREATED_ARCHIVES="${CREATED_ARCHIVES}${archive}\n"
	return 0
}
makeArchiveSourcesWithGitFrom() {
	local project archive_all
	project=$1

	makeArchiveAll "$project" || {
		exit 2
	}
	archive_all="${CREATED_ARCHIVE}"
	log_info "Created archive with git history '${GREEN}${archive_all}${COLOR_RESET}'"
	CREATED_ARCHIVES="${CREATED_ARCHIVES}${archive_all}\n"
	return 0
}
makeArchiveWithModifiedOrNewFrom() {
	local project archive_modified
	project=$1

	makeArchiveModifiedOrNew "$project" || {
		exit $?
	}
	archive_modified="${CREATED_ARCHIVE}"
	log_info "Created archive with modified or new files '${GREEN}${archive_modified}${COLOR_RESET}'"
	CREATED_ARCHIVES="${CREATED_ARCHIVES}${archive_modified}\n"
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
		exit 3
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
#		exit 5
#	}
#	exit 0
#}

_owd="$(pwd)"

while read p ; do

	log_info "Dealing with ${BLUE}'$p'${COLOR_RESET}..."
	{
		log_debug "Entering ${YELLOW}'${p}'${COLOR_RESET}"
		cd "$p" || {
			log_error "Could not cd into '${YELLOW}$p${COLOR_RESET}'"
			exit $ERROR_PROJECT_DIRECTORY_NOT_ACCESSIBLE
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

		cd "$_owd"
	} || {
		log_error "Fatal Error : Unable create archive for '${BLUE}$p${COLOR_RESET}'"
		exit 1
	}
	
done <<< "$projects"

log_debug "Created archive(s) : '$CREATED_ARCHIVES'"

[ "x$PUSH_TO" != "x" ] && {
	putAllTo "$PUSH_TO"
}

exit 0

