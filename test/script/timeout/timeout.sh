#!/bin/bash

pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../../.."
popd > /dev/null
test_root_dir="${root_dir}/test"


oneTimeSetUp() {
	export MDU_LOG_LEVEL=warn
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

testFastCommand() {
    local result output
    output="$("${root_dir}/timeout.sh" -t15 -i1 "${test_root_dir}/resources/fetch_from_far_away_and_dump.sh")"
    result=$?
    assertEquals 0 ${result}
    assertEquals "${expected_10_fetched}" "${output}"
}

testFastCommandWithParameter() {
    local result output
    output="$("${root_dir}/timeout.sh" -t15 -i1 "${test_root_dir}/resources/fetch_from_far_away_and_dump.sh" 2)"
    result=$?
    assertEquals 0 ${result}
    local expected="Fetching data 1...
Fetching data 2...
Done : All fetched"
    assertEquals "${expected}" "${output}"
}

testCommand() {
    local result output
    output="$("${root_dir}/timeout.sh" -t5 -i1 "${test_root_dir}/resources/fetch_from_far_away_and_dump.sh")"
    result=$?
    assertNotSame "${expected_10_fetched}" "${output}"
}

testCommandCancelWithStdoutRegex() {
    local result output

    output="$("${root_dir}/timeout.sh" -t 5 -i 1 -c stdout:data\ 2 "${test_root_dir}/resources/fetch_from_far_away_and_dump.sh" 10)"
    result=$?

    assertEquals "${expected_10_fetched}" "${output}"
}

testCommandCancelWithWrongStdoutRegex() {
    local result output

    output="$("${root_dir}/timeout.sh" -t 5 -i 1 -c stdout:nooope "${test_root_dir}/resources/fetch_from_far_away_and_dump.sh" 10)"
    result=$?

    assertNotSame "${expected_10_fetched}" "${output}"
}



. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2" || exit 4
[ ${__shunit_testsFailed} -gt 0 ] && exit 5 || exit 0

