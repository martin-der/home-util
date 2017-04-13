#!/bin/sh

cat "$1" | build/tool/shdoc/shdoc > "$2"