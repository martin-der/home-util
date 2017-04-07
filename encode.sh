#!/bin/bash


#
# param 1 : string to escape to URL encoding
#
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

#
# param in : string to escape to html
#
function encodeHtml() {
	sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

