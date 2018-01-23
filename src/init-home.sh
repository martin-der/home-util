#!/usr/bin/env bash

TAG="[INIT-USER-HOME]"
export TAG


source "$(dirname "$0")/shell-util.sh" 2>/dev/null || source shell-util  || exit 1
load_source_once config-util sh || exit 1


if test "x${USER:-}" = "x" ; then
	log_warn "Environment variable 'USER' is empty or undefined"
fi


CONFIGURATION_FILE="$HOME/.config/mdu/init.properties"

CONFIG_2_ENV_LIST="directory.bin=BIN_DIR
directory.local=LOCAL_DIR
directory.project.dev=PROJECTS_DEV_DIR
link.executable.sourceDirectory=EXECUTABLE_SOURCE_DIR
link.executable.elements=EXECUTABLE_LIST
link.elements=LINK_LIST
share.name=SHARE_NAME
share.publicDirectory.enabled=SHARE_PUBLIC_DIRECTORY:boolean
share.samba.enabled=SHARE_WITH_SAMBA:boolean"


exit_code=0

handle_error() {
	[ $exit_code -lt $1 ] && exit_code=$1
	log_error "$2"
} 

function parseConfig() {
	config="$(cat "$1" | sed  '                                                                                                                                                                                     
: again                                                                                                                                                                                       
/\\$/ {                                                                                                                                                                                       
    N                                                                                                                                                                                         
    s/\\\n/\\\\n/                                                                                                                                                                                  
    t again                                                                                                                                                                                   
}')"
	while read l ; do
		line_isEmpty "$l"  && continue
		line_isComment_withSharp "$l" && continue
		KEY="$(line_KeyValue_getKey "$l")"
		VALUE="$(line_KeyValue_getValue "$l")"
		VALUE="$(echo "$VALUE" | sed 's/^\"\(.*\)\"$/\1/')"
		VALUE="$(echo "$VALUE" | sed 's#\\n#\n#g')"
		VALUE=$(eval "echo \"$VALUE\"")

		log_debug "Key = $KEY Value = $VALUE"
		convertConfigKeyAndExportToEnvVariableIfExists "$KEY" "$VALUE" "$CONFIG_2_ENV_LIST" "$ENV_PREFIX" || {
			log_warn "Unknown config '$KEY'"
		}
	done <<< "$config"
}



function createXDGDirectory() {
	local result=0
	NAME=$1
	XDG_DIR="$2"
	if test ! -e "$XDG_DIR" ; then
		log_info "Create XDG directory for «$NAME» : «$XDG_DIR»"
		mkdir -p "$XDG_DIR" || result=1
	else
		if test ! -d "$XDG_DIR" ; then
			log_info "XDG «$NAME» exists but it's not a directory"
		fi
	fi
	return ${result}
}

function publicDirectoryWithSamba {
	local DIRECTORY=$1

	if test "x${USER+}" = "x" ; then
		handle_error 1 "Cannot create samba share without 'USER' variable defined"
		return 1
	fi

	local SHARE_NAME="$USER - Documents"
	local ACTUAL_SHARE_INFO="$(net usershare info "$SHARE_NAME")"
	if test $? -ne 0 ; then
		log_warn "Samba server utilities don't seem to be available"
		return 2
	fi


	if test "x$ACTUAL_SHARE_INFO" == "x" ; then
		log_info "Publish «$DIRECTORY» via a Samba share named «$SHARE_NAME»"
		net usershare add "$SHARE_NAME" "$DIRECTORY" "$SHARE_NAME" everyone:R guest_ok=y || handle_error 2 "Could not create samba share «$SHARE_NAME»"
	else
		local ACTUAL_SHARE_PATH="$(echo "$ACTUAL_SHARE_INFO" | properties_find path)"
		local ACTUAL_SHARE_ACL="$(echo "$ACTUAL_SHARE_INFO" | properties_find usershare_acl)"
		local ACTUAL_SHARE_GUESTOK="$(echo "$ACTUAL_SHARE_INFO" | properties_find guest_ok)"
		local same_share=1
		if test "x$DIRECTORY" != "x$ACTUAL_SHARE_PATH"; then
			same_share=0
		fi
		if test $same_share -eq 0 ; then
			log_warn "«$DIRECTORY» already published via Samba with a different configuration"
			log_info "path = $ACTUAL_SHARE_PATH"
			log_info "usershare_acl = $ACTUAL_SHARE_ACL"
			log_info "guest_ok = $ACTUAL_SHARE_GUESTOK"
		else
			log_debug "«$DIRECTORY» already published via Samba"
		fi
	fi
}

function makeDirectoryPublic() {
	local DIRECTORY="$1"

	local group_read_permission="$(stat -c %A "$DIRECTORY" | sed 's/^d...\(.\)..\(.\)..$/\1/')"
	local other_read_permission="$(stat -c %A "$DIRECTORY" | sed 's/^d...\(.\)..\(.\)..$/\2/')"

	if [ "x$group_read_permission" != xr -o "x$other_read_permission" != xr ] ; then
		log_info "Make «$DIRECTORY» truly public : 'chmod' it"
		chmod g+r,o+r "$DIRECTORY"
	fi

	[ ${SHARE_WITH_SAMBA:-0} -ne 0 ] && {
		if command_exists net ; then
			publicDirectoryWithSamba "$DIRECTORY"
		else
			handle_error 2 "Cannot publish with samba, command unavailable"
		fi
	}
}

function cleanFilename() {
	cleaned_filename="$(echo "$1" | sed 's#^\(.*\)\.sh$#\1#')"
	echo "$cleaned_filename"
	if test "x$cleaned_filename" == "x$1" ; then
		return 0
	else
		return 1
	fi
}

function createLink() {
	local WHERE="$1"
	local TARGET="$2"

	log_debug "Does a link «$WHERE» exists ?"
	if test ! -e "$WHERE" ; then
		log_info "Create link to «$TARGET» in «$WHERE»"
		local DIRNAME="$(dirname "$WHERE")"
		test -e "$DIRNAME" || {
			log_debug "Create directory «$DIRNAME» for link"
			mkdir -p "$DIRNAME" || return 2
		}
		ln -s "$TARGET" "$WHERE" || return 2
	else
		if test ! -h "$WHERE" ; then
			log_warn "«$WHERE» exists but it's not a link"
			return 1
		fi
	fi
	return 0
}

function createLinkInBin() {
	local SOURCE="$1"
	local FILENAME="$(basename "$SOURCE")"
	local BIN_LINK="$BIN_DIR/$(cleanFilename "$FILENAME")"

	createLink "$BIN_LINK" "$SOURCE" && [ ! -e "$BIN_LINK" ] && {
		log_warn "Link '$BIN_LINK' is broken"
	}
}


if [ -f "$CONFIGURATION_FILE" -a -r "$CONFIGURATION_FILE" ] ; then
	parseConfig "$CONFIGURATION_FILE"
else
	log_error "File '$CONFIGURATION_FILE' doesn't exists or is not readable, aborting"
	exit 2
fi


log_debug "$(printVariable EXECUTABLE_SOURCE_DIR)"
log_debug "$(printVariable EXECUTABLE_LIST)"
log_debug "$(printVariable BIN_DIR)"
log_debug "$(printVariable LINK_LIST)"
log_debug "$(printVariable SHARE_WITH_SAMBA)"
log_debug "$(printVariable SHARE_NAME)"


if [ -f "$HOME/.config/user-dirs.dirs" -a -r "$HOME/.config/user-dirs.dirs" ] ; then
	log_debug "Create XDG Directories"
	while read l ; do
		line_isComment_withSharp "$l" && continue
		line_isEmpty "$l" && continue
		KEY="$(line_KeyValue_getKey "$l")"
		VALUE="$(line_KeyValue_getValue "$l")"
		VALUE="$(echo "$VALUE" | sed 's/^\"\(.*\)\"$/\1/')"
		eval VALUE="$VALUE"
		log_debug "XDG Directory Name = «$KEY» Path = «$VALUE»"
		createXDGDirectory "$KEY" "$VALUE"

		if test "$KEY" = "XDG_PUBLICSHARE_DIR" ; then
			makeDirectoryPublic "$VALUE"
		fi
	done < "$HOME/.config/user-dirs.dirs"
else
	log_info "File '$HOME/.config/user-dirs.dirs' doesn't exists or is not readable, hence No XDG directories will be created"
fi

[ ! -z ${LINK_LIST+x} ] && {
	log_debug "Create custom symbolic links"
	while read l ; do

		line_isEmpty "$l" && continue

		regex_for_where="s/^\(.*\)->\(.*\)$/\1/"
		regex_for_target="s/^\(.*\)->\(.*\)$/\2/"

		where="$(echo "$l" | sed "$regex_for_where" )"
		target="$(echo "$l" | sed "$regex_for_target" )"

		if test "x$target" == "x" -o "x$where" == "x" ; then
			log_warn "Invalid link configuration : '$l'"
		else
			createLink "$where" "$target"
		fi
	done <<< "$LINK_LIST"
}

[ ! -z ${BIN_DIR+x} ] && {
	[ ! -d "$BIN_DIR" ] && {
		log_debug "Create bin directory '$BIN_DIR'"
		mkdir "$BIN_DIR" || handle_error 2 "Failed to create bin directory '$BIN_DIR'"
	}
	[ -d "$BIN_DIR" ] && {
		[ ! -z ${EXECUTABLE_LIST+x} ] && [ ! -z ${EXECUTABLE_SOURCE_DIR+x} ] && {
			log_debug "Create executables symbolic links in bin directory"
			while read f ; do
				createLinkInBin "$EXECUTABLE_SOURCE_DIR/$f"
			done <<< "${EXECUTABLE_LIST}"
		} 
	} 
}

exit $exit_code

