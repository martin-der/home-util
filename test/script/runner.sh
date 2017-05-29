#!/bin/bash

src_root_dir="${MDU_SHELLTEST_PROJECT_DIRECTORY}/src"
test_root_dir="${MDU_SHELLTEST_PROJECT_DIRECTORY}/test"

test_common_resources_dir="${test_root_dir}/resources/common"
test_resources_dir="${test_root_dir}/resources/specific/${MDU_SHELLTEST_TEST_NAME}"

export PATH="$src_root_dir:$PATH"


source "$MDU_SHELLTEST_TESTUNIT_RUNNER_INCLUDE"
