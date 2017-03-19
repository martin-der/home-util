#!/usr/bin/env bash

load_source "holy-grail" || return 1


echo "The holy grail is located at '${holygrail_position:-}'"
