#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/../runner.sh"


exit 0

oneTimeSetUp() {
    expected_10_fetched="Fetching data 1...
Fetching data 2...
Fetching data 3...
Fetching data 4...
Fetching data 5...
Fetching data 6...
Fetching data 7...
Fetching data 8...
Fetching data 9...
Fetching data 10...
Done : All fetched"

}

timeout() {
	"${src_root_dir}/timeout.sh" "$@"
}


testFastCommand() {
    local result output
    output="$(timeout -t15 -i1 "${test_common_resources_dir}/fetch_from_far_away_and_dump.sh")"
    result=$?
    assertEquals 0 ${result}
    assertEquals "${expected_10_fetched}" "${output}"
}

testFastCommandWithParameter() {
    local result output
    output="$(timeout -t15 -i1 "${test_common_resources_dir}/fetch_from_far_away_and_dump.sh" 2)"
    result=$?
    assertEquals 0 ${result}
    local expected="Fetching data 1...
Fetching data 2...
Done : All fetched"
    assertEquals "${expected}" "${output}"
}

testCommand() {
    local result output
    output="$(timeout -t5 -i1 "${test_common_resources_dir}/fetch_from_far_away_and_dump.sh")"
    result=$?
    assertNotSame "${expected_10_fetched}" "${output}"
}

testCommandCancelWithStdoutRegex() {
    local result output

    output="$(timeout -t 5 -i 1 -c stdout:data\ 2 "${test_common_resources_dir}/fetch_from_far_away_and_dump.sh" 10)"
    result=$?

    assertEquals "${expected_10_fetched}" "${output}"
}

testCommandCancelWithWrongStdoutRegex() {
    local result output

    output="$(timeout -t 5 -i 1 -c stdout:nooope "${test_common_resources_dir}/fetch_from_far_away_and_dump.sh" 10)"
    result=$?

    assertNotSame "${expected_10_fetched}" "${output}"
}


runTests
