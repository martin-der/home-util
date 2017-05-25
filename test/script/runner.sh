#!/bin/bash

src_root_dir="${MDU_SHELLTEST_PROJECT_DIRECTORY}/src"
test_root_dir="${MDU_SHELLTEST_PROJECT_DIRECTORY}/test"

export PATH="$src_root_dir:$PATH"


source "$MDU_SHELLTEST_TESTUNIT_RUNNER_INCLUDE"
