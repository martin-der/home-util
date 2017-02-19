#!/bin/bash
#@mdu-helper-capable

source "$(dirname "$0")/shell-util.sh" 2>/dev/null || source shell-util || exit 1
source "$(dirname "$0")/completion-helper.sh" 2>/dev/null || source completion-helper || exit 1


if [ -z ${MDU_OPT_DIRECTORY+x} ] ; then
	APPS_DIR="/opt"
else
	APPS_DIR="$MDU_OPT_DIRECTORY"
fi


ACTION_HELP="help"
ACTION_APPLICATIONS="applications"
ACTION_APPLICATION_CREATE="create"
ACTION_APPLICATION_ALTERNATIVES="alternatives"
ACTION_APPLICATION_SHOW_ALTERNATIVE="show"
ACTION_APPLICATION_CHOOSE_ALTERNATIVE="choose"
ACTION_APPLICATION_INSTALL_ALTERNATIVE="install"
ACTION_APPLICATION_UNINSTALL_ALTERNATIVE="uninstall"

ARGTYPE_APPLICATION="application"
ARGTYPE_ALTERNATIVE="alternative"


ERROR_NO_SUCH_ACTION=3
ERROR_INVALID_PARAMETER=8
ERROR_EXECUTION_FAILED=20

DRYDO=""
#DRYDO=echo





function listActions() {
	compgen -X ACTION_ -A variable -v | while read action ; do
		echo "$action" | grep -q "^ACTION_" && echo "${!action}"
	done
}
function completeType() {
	argumentType="$1"
	shift
	action="$1"
	shift
	case $argumentType in
		"$ARGTYPE_APPLICATION")
			listApplications ;;
		"$ARGTYPE_ALTERNATIVE")
			listAlternatives $@ ;;
		*)
			return 1 ;;
	esac

	return 0
}
function getActionArguments() {
	case "$1" in
		$ACTION_APPLICATION_CREATE)
			echo "<name:string>" ;;
		$ACTION_APPLICATION_INSTALL_ALTERNATIVE)
			echo "<application:${ARGTYPE_APPLICATION}> <source:file> [<alternative:string>]" ;;
		$ACTION_APPLICATION_UNINSTALL_ALTERNATIVE)
			echo "<application:${ARGTYPE_APPLICATION}> <alternative:${ARGTYPE_ALTERNATIVE}>" ;;
		$ACTION_APPLICATION_SHOW_ALTERNATIVE)
			echo "<application:${ARGTYPE_APPLICATION}> <alternative:${ARGTYPE_ALTERNATIVE}>" ;;
		$ACTION_APPLICATION_CHOOSE_ALTERNATIVE)
			echo "<application:${ARGTYPE_APPLICATION}> <alternative:${ARGTYPE_ALTERNATIVE}>" ;;
		*)
			return 1 ;;
	esac

	return 0
}
function getInformation() {
	local info="$1"
	local name="$2"
	local what="$3"
	local action parameterType

	[ "x$what" == "x" ] && {
		[ "x$info" == "xsummary" ] && echo "Installation of 'optionnal' packages made easy"
		[ "x$info" == "xdetail" ] && echo "${_mdu_CH_application} eases the installation of optionnal package ( usually found under '/opt/' )"
		return 0
	}

	[ "x$what" == "xtype" ] && {
		case "$name" in
			${ARGTYPE_APPLICATION})
				[ "x$info" == "xsummary" ] && echo "Name of an application"
				[ "x$info" == "xdetail" ] && {
					echo "This is the name of a application. Applications are stored in the folder given par the environement variable 'MDU_OPT_DIRECTORY'"
					echo "The command '$ACTION_APPLICATIONS' can also list the existing applications."
				}
				;;
			${ARGTYPE_ALTERNATIVE})
				[ "x$info" == "xsummary" ] && echo "Name of an alternative"
				[ "x$info" == "xdetail" ] && {
					echo "This is the name of an alternative as it can be found in the folder of the application."
					echo "The command '$ACTION_APPLICATION_SHOW_ALTERNATIVE' can also list the alternatives for a application."
				}
				;;
		esac
		return 0
	}

	[ "x$what" == "xverb" ] && {
		case "$name" in
			$ACTION_APPLICATIONS)
				[ "x$info" == "xsummary" ] && echo "List applications"
				;;
			$ACTION_APPLICATION_ALTERNATIVES)
				[ "x$info" == "xsummary" ] && echo "List installed alternatives for an application"
				;;
			$ACTION_APPLICATION_CREATE)
				[ "x$info" == "xsummary" ] && echo "Create a new application"
				;;
			$ACTION_APPLICATION_INSTALL_ALTERNATIVE)
				[ "x$info" == "xsummary" ] && echo "Install a new alternative for the given application." \
				|| {
					echo "New alternative may come bundled in an archive, from a directory or from an URL. In the later case, the URL must resolve to an archive or directory."
					echo "URL's types that can be processed and archive that can be unpacked depend on the commands available."
					echo "Notice : If the application doesn't exist it will be created in the process."
				}
				;;
			$ACTION_APPLICATION_UNINSTALL_ALTERNATIVE)
				[ "x$info" == "xsummary" ] && echo "Remove an alternative for an application"
				;;
			$ACTION_APPLICATION_SHOW_ALTERNATIVE)
				[ "x$info" == "xsummary" ] && echo "Show currently selected alternative for an application"
				[ "x$info" == "xdetail" ] && {
					echo "return 0 only if an alternative if selected"
				}
				;;
			$ACTION_APPLICATION_CHOOSE_ALTERNATIVE)
				[ "x$info" == "xsummary" ] && echo "Choose an alternative for an application"
				;;
			*)
				return 1 ;;
		esac
	}

	return 0
}


ACTION="$1"
shift

_mdu_CH_init_builder_helper "listActions" "getActionArguments" "getInformation" "completeType" "$ACTION" $@

function printHelp() {
	_mdu_CH_print_help $@
}

function checkApplicationExists() {
	APPLICATION="$1"
	if test -d "${APPS_DIR}/${APPLICATION}.d" && test -x "${APPS_DIR}/${APPLICATION}.d" ; then
		return 0
	else
		return 1
	fi
}
function checkApplicationAlternativeExists() {
	APPLICATION="$1"
	ALTERNATIVE="$2"
	ALT_THING="${APPS_DIR}/${APPLICATION}.d/${ALTERNATIVE}"
	if test -d "${ALT_THING}" || test -f "${ALT_THING}" ; then
		return 0
	else
		return 1
	fi
}
function checkApplicationDoesntExistOrDie() {
	APPLICATION="$1"
	checkApplicationExists "$APPLICATION" && {
		log_error "Application '$APPLICATION' already exists"
		exit $ERROR_INVALID_PARAMETER
	}
}
function checkApplicationExistsOrDie() {
	APPLICATION="$1"
	checkApplicationExists "$APPLICATION" || {
		log_error "No such application '$APPLICATION'"
		exit $ERROR_INVALID_PARAMETER
	}
}
function checkApplicationAlternativeExistsOrDie() {
	APPLICATION="$1"
	ALTERNATIVE="$2"
	checkApplicationAlternativeExists "$APPLICATION" "${ALTERNATIVE}" || {
		log_error "No such alternative '$ALTERNATIVE' for application '$APPLICATION'"
		exit $ERROR_INVALID_PARAMETER
	}

}
function checkApplicationAlternativeDoesntExistOrDie() {
	APPLICATION="$1"
	ALTERNATIVE="$2"
	checkApplicationAlternativeExists "$APPLICATION" "${ALTERNATIVE}" && {
		log_error "Alternative '$ALTERNATIVE' already exists for application '$APPLICATION'"
		exit $ERROR_INVALID_PARAMETER
	}
}



function extract {
	commandPrefix="$(extractCommandPrefix "$1")" || {
		log_error "Unknown archive type"
		return 1
	}

	log_debug "command is : $commandPrefix $1"
	$DRYDO $commandPrefix "$1" > /dev/null || {
		log_error "Error while extracting archive"
		return 1
	}

	return 0
}
function extractCommandPrefix {
	case $1 in
		*.tar.bz2) echo "tar xvjf" ;;
		*.tar.gz) echo "tar xvzf" ;;
		*.tar.xz) echo "tar xvJf" ;;
		*.lzma) echo "unlzma" ;;
		*.bz2) echo "bunzip2" ;;
		*.rar) echo "unrar x -ad" ;;
		*.gz) echo "gunzip" ;;
		*.tar) echo "tar xvf" ;;
		*.tbz2) echo "tar xvjf" ;;
		*.tgz) echo "tar xvzf" ;;
		*.zip) echo "unzip" ;;
		*.Z) echo "uncompress" ;;
		*.7z) echo "7z x" ;;
		*.xz) echo "unxz" ;;
		*.exe) echo "cabextract" ;;
		*) return 1 ;;
	esac
	return 0
}

function checkApplicationNameIsValid() {
	echo "$1" | grep -q '^.*\.d$' > /dev/null  && {
		echo -n "Must not end with '.d'"
		return 1
	}
	echo "$1" | grep -q '/' > /dev/null && {
		echo -n "Must not contains '/'"
		return 1
	}
	return 0
}
function checkApplicationNameIsValidOrDie() {
	problem="$(checkApplicationNameIsValid "$1")" || {
		log_error "Invalid application name : $problem"
		exit $ERROR_INVALID_PARAMETER
	}
}

function createApplicationDooo() {
	APPLICATION="$1"

	APP_DIR="${APPS_DIR}/${APPLICATION}.d"

	$DRYDO mkdir -p "${APP_DIR}" || exit $ERROR_EXECUTION_FAILED

	log_info "Application '$APPLICATION' has been created"

	return 0
}

function listAlternatives() {
	APPLICATION="$1"
	APP_DIR="${APPS_DIR}/${APPLICATION}.d"
	APP_DIR_SLASH="${APP_DIR}/"
	prefix_length="${#APP_DIR_SLASH}"
	find "${APP_DIR}" -mindepth 1 -maxdepth 1 -type d -o -type f | while read alternative ; do
		echo ${alternative:${prefix_length}}
	done
}

function showAlternative() {
	APPLICATION="$1"

	APP_DIR="${APPS_DIR}/${APPLICATION}.d"
	APP_DIR_escaped="$(escaped_for_regex "$APP_DIR")"

	ALTERNATIVE_LINK="${APPS_DIR}/${APPLICATION}"

	log_debug "Check link '$ALTERNATIVE_LINK' for alternative"
	if test -L "$ALTERNATIVE_LINK" ; then

		ALTERNATIVE="$(readlink -f "$ALTERNATIVE_LINK")"
		#ALTERNATIVE_LINK="$(realpath "${APPS_DIR}/${APPLICATION}")"


		if test -e "$ALTERNATIVE" ; then

			ALTERNATIVE_NAME="$(basename "$ALTERNATIVE")"

			echo "$ALTERNATIVE_NAME"

			log_info "Application '$APPLICATION' uses '$ALTERNATIVE_NAME)' alternative"

			return 0
		else
			log_warn "Application '$APPLICATION' uses a invalid alternative : link '$ALTERNATIVE_LINK'->'$ALTERNATIVE' is broken"
		fi
	fi

	log_info "There is no alternative set for application '$APPLICATION'"
	return 1
}
function setAlternative() {
	APPLICATION="$1"
	ALTERNATIVE="$2"

	APP_DIR="${APPS_DIR}/${APPLICATION}.d"
	ALTERNATIVE_LINK="${APPS_DIR}/${APPLICATION}"
	ALT_THING="${APPLICATION}.d/${ALTERNATIVE}"

	$DRYDO rm -f "${ALTERNATIVE_LINK}" || exit $ERROR_EXECUTION_FAILED
	$DRYDO ln -s "${ALT_THING}" "${ALTERNATIVE_LINK}" || exit $ERROR_EXECUTION_FAILED

	log_info "Application '$APPLICATION' now uses '$ALTERNATIVE' alternative"
}



function listApplications() {
	APPS_DIR_escaped="$(escaped_for_regex "$APPS_DIR")"
	find "${APPS_DIR}" -maxdepth 1 -type d -name '*.d' | while read appdir ; do
		sed "s#^${APPS_DIR_escaped}/\(.*\)\.d\$#\1#" <<< "$appdir"
	done
}

[ $mdu_CH_exit -eq 1 ] && {
	return 0
}

function installAlternative() {
	APPLICATION="$1"
	SOURCE="$2"
	[ -z ${3+x} ] || ALTERNATIVE_NAME="${3}"

	APP_DIR="${APPS_DIR}/${APPLICATION}.d"
	SOURCE_NAME="$(basename "$SOURCE")"

	DESTINATION="${APP_DIR}/${ALTERNATIVE_NAME-${SOURCE_NAME}}"

	TMP_DIR=`mktemp -d`
	trap "rm -rf $TMP_DIR" EXIT
	log_debug "Working in $TMP_DIR"

	if test -f "$SOURCE" ; then

		log_debug "Install destination is '$DESTINATION'"

		(
		$DRYDO cp "$SOURCE" "$TMP_DIR/$SOURCE_NAME" || exit $ERROR_EXECUTION_FAILED
		$DRYDO cd "$TMP_DIR" || exit $ERROR_EXECUTION_FAILED
		log_info "Installing '$SOURCE_NAME'..."
		log_debug "Extracting archive..."
		extract "$TMP_DIR/$SOURCE_NAME" || exit $ERROR_EXECUTION_FAILED
		$DRYDO rm -f "$TMP_DIR/$SOURCE_NAME" || exit $ERROR_EXECUTION_FAILED
		log_debug "Moving folder..."
		count_files=$(ls -1 "$TMP_DIR" | wc -l)
		if test $count_files -gt 1 ; then
			$DRYDO mv "$TMP_DIR" "$DESTINATION" || exit $ERROR_EXECUTION_FAILED
		else
			SINGLE_FOLDER_NAME="$(ls -1 "$TMP_DIR")"
			$DRYDO test "x$SINGLE_FOLDER_NAME" != "x" || exit $ERROR_EXECUTION_FAILED
			$DRYDO mv "$TMP_DIR/$SINGLE_FOLDER_NAME" "$DESTINATION" || exit $ERROR_EXECUTION_FAILED
		fi
		)

		log_info "Alternative '$SOURCE' for application '$APPLICATION' successfully installed in '$DESTINATION'"
	elif test -d "$SOURCE" ; then

		log_debug "Copying folder from '$SOURCE' to '$DESTINATION'"
		$DRYDO cp -r "$SOURCE" "$DESTINATION" || exit $ERROR_EXECUTION_FAILED

		log_info "Alternative '$SOURCE' for application '$APPLICATION' successfully installed in '$DESTINATION'"
	else
		log_error "Does not exist or is not a file or directory : '$SOURCE'"
		exit 100
	fi

}
function uninstallAlternative() {
	APPLICATION="$1"
	ALTERNATIVE="$2"

	APP_DIR="${APPS_DIR}/${APPLICATION}.d"
	DESTINATION="${APP_DIR}/${ALTERNATIVE}"


	$DRYDO rm -rf "$DESTINATION" || exit $ERROR_EXECUTION_FAILED

	log_info "Alternative '$ALTERNATIVE' (in '$DESTINATION') for application '$APPLICATION' was uninstalled"
}

# $1 Argument
# $2 Argument name
# $3 [Optionnal] Argument position
function dieIfArgumentMissing() {
	test "x$1" == "x" && {
		MSG="Argument '$2' expected"
		test "x$3" != "x" && MSG="$MSG at pos $3"
		log_error "$MSG"
		exit 1
	}
}

function createApplication() {
	APPLICATION="$1"

	dieIfArgumentMissing "$APPLICATION" "Application" 2
	checkApplicationDoesntExistOrDie "$APPLICATION"
	checkApplicationNameIsValidOrDie "$APPLICATION"

	createApplicationDooo "$APPLICATION"
}

function listApplicationAlternatives() {
	APPLICATION="$1"

	dieIfArgumentMissing "$APPLICATION" "Application" 2
	checkApplicationExistsOrDie "$APPLICATION"

	listAlternatives "$APPLICATION"
}

function showApplicationAlternative() {
	APPLICATION="$1"
	dieIfArgumentMissing "$APPLICATION" "Application" 2
	checkApplicationExistsOrDie "$APPLICATION"

	showAlternative "$APPLICATION"
}
function chooseApplicationAlternative() {
	APPLICATION="$1"
	ALTERNATIVE="$2"

	dieIfArgumentMissing "$APPLICATION" "Application" 2
	checkApplicationExistsOrDie "$APPLICATION"
	dieIfArgumentMissing "$ALTERNATIVE" "Alternative" 3
	checkApplicationAlternativeExistsOrDie "$APPLICATION" "$ALTERNATIVE"

	setAlternative "$APPLICATION" "$ALTERNATIVE"
}

function installApplicationAlternative() {
	APPLICATION="$1"
	SOURCE="${2-}"
	ALTERNATIVE_NAME="${3-}"

	dieIfArgumentMissing "$APPLICATION" "Application" 2
	checkApplicationExistsOrDie "$APPLICATION"
	dieIfArgumentMissing "$SOURCE" "Source" 3
	[ "x$ALTERNATIVE_NAME" == "x" ] || checkApplicationAlternativeDoesntExistOrDie "$APPLICATION" "$ALTERNATIVE_NAME"

	checkApplicationExists "$APPLICATION" || createApplication "$APPLICATION"

	installAlternative $@
}
function uninstallApplicationAlternative() {
	APPLICATION="$1"
	ALTERNATIVE="$2"

	dieIfArgumentMissing "$APPLICATION" "Application" 2
	checkApplicationExistsOrDie "$APPLICATION"
	dieIfArgumentMissing "$ALTERNATIVE" "Alternative" 3
	checkApplicationAlternativeExistsOrDie "$APPLICATION" "$ALTERNATIVE"

	uninstallAlternative "$APPLICATION" "$ALTERNATIVE"
}

dieIfArgumentMissing "$ACTION" "Action" 1

if test "x$ACTION" == "x$ACTION_HELP" ; then
	printHelp $@
	exit 0
fi

log_info "Opt directory = '$APPS_DIR'"

if test "x$ACTION" == "x$ACTION_APPLICATIONS" ; then
	listApplications
elif test "x$ACTION" == "x$ACTION_APPLICATION_CREATE" ; then
	createApplication $@
elif test "x$ACTION" == "x$ACTION_APPLICATION_ALTERNATIVES" ; then
	listApplicationAlternatives $@
elif test "x$ACTION" == "x$ACTION_APPLICATION_SHOW_ALTERNATIVE" ; then
	showApplicationAlternative $@
elif test "x$ACTION" == "x$ACTION_APPLICATION_CHOOSE_ALTERNATIVE" ; then
	chooseApplicationAlternative $@
elif test "x$ACTION" == "x$ACTION_APPLICATION_INSTALL_ALTERNATIVE" ; then
	installApplicationAlternative $@
elif test "x$ACTION" == "x$ACTION_APPLICATION_UNINSTALL_ALTERNATIVE" ; then
	uninstallApplicationAlternative $@
else
	log_error "No such action '$ACTION'"
	printHelp >&2
	exit $ERROR_NO_SUCH_ACTION
fi


