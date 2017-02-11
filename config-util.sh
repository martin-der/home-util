#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/shell-util.sh" 2>/dev/null || source shell-util  || exit 1

# param 1 : key
# param 2 : value
# param 3 : list of '<confKey>=<envVar>' ( separated by CR )
# param 4 : [optional] prefix, added to the name of created environment var
# If key is in the list, then an environment variable named '<[prefix]envVar>' is exported.
function convertConfigKeyAndExportToEnvVariableIfExists() {
	local KEY="$1"
	local VALUE="$2"
	local KEY_TO_ENV_LIST="$3"
	local PREFIX="${4:-}"
	local env_name
	env_name="$(find_property "$KEY" <<< "$KEY_TO_ENV_LIST" )"
	local result=$?
	log_debug "env_name = '$env_name'"
	if [ $result -eq 0 ] ; then
		env_name="$PREFIX$env_name"
		log_debug "export '$env_name'='$VALUE'"
		export "$env_name"="$VALUE"
	fi
	return $result
}

