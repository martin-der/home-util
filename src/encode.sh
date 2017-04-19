#!/bin/bash


# @description Escape a string for URL parameter
#
# @arg $1 string text to convert
# @stdout the string escaped for url use
#
# @exitcode 0
function encodeUrl() {
    local l="${#1}"
    for (( i = 0; i < l; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}

# @description Escape a string for HTML
#
# @arg $1 string text to convert
# @stdout the string escaped for HTML use
#
# @exitcode 0
function encodeHtml() {
	sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g' <<< "$1"
}

