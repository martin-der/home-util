#!/bin/bash

source "$(dirname "$0")/shell-util" 2>/dev/null || source shell-util  || exit 1

# param 1 : key
# param 2 : value
# param 3 : list of '<confKey>=<envVar>' ( separated by CR )
# param 4 : [optional] prefix, added to the name of created environment var
# If key is in the list, then an environment variable named '<[prefix]envVar>' is exported.
function convertConfigKeyAndExportToEnvVariableIfExists() {
	local KEY="$1"
	local VALUE="$2"
	local KEY_TO_ENV_LIST="$3"
	local PREFIX="$4"
	local ENV_NAME="$(properties_find "$KEY" <<< "$KEY_TO_ENV_LIST" )"
	local result=$?
	log_debug "ENV_NAME = '$ENV_NAME'"
	if [ $result -eq 0 ] ; then
		ENV_NAME="$PREFIX$ENV_NAME"
		log_debug "export '$ENV_NAME'='$VALUE'"
		export "$ENV_NAME"="$VALUE"
	fi
	return $result
}

