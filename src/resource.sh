#!/bin/bash

source "$(dirname "$0")/shell-util.sh" 2>/dev/null || source shell-util || exit 1


function fetchResource() {
	local RESOURCE="$1"
	local DESTINATION="$2"

	grep -e '^https\?\|^ftp:' "$RESOURCE" && {
		download "$RESOURCE" "$DESTINATION" || return $?
		return 0
	}
	grep -e '^git:' && {
		git clone "$RESOURCE" "$DESTINATION" || return $?
		return 0
	}
	grep -e '^ssh:' && {
		scp "$RESOURCE" "$DESTINATION" || return $?
		return 0
	}

}

function download() {
	local SOURCE="$1"
	local DESTINATION="$2"
	which wget >/dev/null 2>&1 && {
		wget "$SOURCE" -O "$DESTINATION" || return 2
		return 0
	}
	wich curl && {
		curl -o "$DESTINATION" "$SOURCE" || return 2
		return 0
	}
	log_error "No command available for downloading"
	return 1
}

function extractArchive {
	local commandPrefix="$(extractArchiveCommand "$1")" || {
		log_error "Unknown archive type"
		return 1
	}

	"$commandPrefix" "$1" > /dev/null || {
		log_error "Error while extracting archive"
		return 2
	}

	return 0
}

function extractArchiveCommand {
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

