#!/bin/bash

source "$(dirname "$0")/shell-util.sh" 2>/dev/null || source shell-util || exit 1


function getResource() {
	local RESOURCE="$1"
	local DESTINATION="$2"

	grep -e '^https?:ftp|' "$RESOURCE"

}

function download() {
	local SOURCE="$1"
	local DESTINATION="$2"
	which wget && {
		wget "$SOURCE" -O "$DESTINATION" && return 1
		return 0
	}
	wich curl && {
		curl -o "$DESTINATION" "$SOURCE" 
		return 0
	}
	echo "No command available for downloading" >&2
	return 2
}

function extractArchive {
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

