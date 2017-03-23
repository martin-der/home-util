#!/bin/bash

source "$(dirname "$0")/shell-util.sh" 2>/dev/null || source shell-util  || exit 1
load_source_once config-util sh || exit 1

CONFIG_2_ENV_LIST="custom-prompt.enable=SHOW_PROMPT
custom-prompt.branch.interesting=INTERESTING_BRANCHES
custom-prompt.remote.interesting=INTERESTING_REMOTES"

ENV_PREFIX="MDU_GIT_"


function parseConfig() {
	CONFIG_FILE="$1"

	while read l ; do 
		line_isEmpty "$l"  && continue
		line_isComment_withSharp "$l" && continue
		KEY="$(line_KeyValue_getKey "$l")"
		VALUE="$(line_KeyValue_getValue "$l")"
		VALUE="$(echo "$VALUE" | sed 's/^\"\(.*\)\"$/\1/')"

		log_debug "Key = $KEY    Value = $VALUE"
		convertConfigKeyAndExportToEnvVariableIfExists "$KEY" "$VALUE" "$CONFIG_2_ENV_LIST" "$ENV_PREFIX" || {
			log_warn "Unknown config '$KEY'"
		}
	done < "$CONFIG_FILE"
}



file_name="$HOME/.config/mdu/git/config"
if test -r "$file_name" ; then
	log_info "Parsing global config «$file_name»"
	parseConfig "$file_name"
fi


GIT_PROJECT_ROOT="$(git rev-parse --show-toplevel 2> /dev/null)" || {
	log_debug "This a not a git repository."
	exit 0 
}

log_debug "Git root = «$GIT_PROJECT_ROOT»"

file_name="$GIT_PROJECT_ROOT/.git/info/mdu/config"
if test -r "$file_name" ; then
	log_info "Parsing local repository config «$file_name»" 
	parseConfig "$file_name"
else
	log_info "No config file for this repository"
fi

