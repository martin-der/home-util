#!/bin/bash

#test_root_dir="$HOME/dev/prog/home-util/test"
pushd "$(dirname "$0")" > /dev/null
root_dir="$(pwd -P)/../.."
popd > /dev/null
test_root_dir="${root_dir}/test"

oneTimeSetUp() {
	export MDU_HUMAN_MODE=0
	export MDU_NO_COLOR=1
	. "${root_dir}/shell-util.sh" || exit 1
	RESOURCES_DIR="${root_dir}/resources"
}

setUp() {
	TMP_DIR=`mktemp -d`
	export MDU_LOG_TAG=
}
tearDown() {
	rm -rf "$TMP_DIR"
}

_assertOutput() {
	local out="$1"
	local err="$2"
	assertEquals "StdOut text is ok" "$out" "$(cat "$TMP_DIR/text_out")"
	assertEquals "StdErr text is ok" "$err" "$(cat "$TMP_DIR/text_err")"
}

testAllLoggingOn() {
	export MDU_LOG_LEVEL=debug
	log_debug "Set steam aperture off" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[DEBUG] Set steam aperture off" ""
	log_info "Working in closed environment" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[INFO] Working in closed environment" ""
	log_warn "OMG, it's heating" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[WARN] OMG, it's heating"
	log_error "Oops, it has exploded" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] Oops, it has exploded"
}

testAllLoggingWhileChangingLogLevel() {
	export MDU_LOG_LEVEL=debug
	log_debug "Set steam aperture off" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[DEBUG] Set steam aperture off" ""
	log_info "Working in closed environment" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[INFO] Working in closed environment" ""
	log_warn "OMG, it's heating" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[WARN] OMG, it's heating"
	log_error "Oops, it has exploded" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] Oops, it has exploded"

	export MDU_LOG_LEVEL=error
	log_debug "Set steam aperture off 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_info "Working in closed environment 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_warn "OMG, it's heating 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_error "Oops, it has exploded 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] Oops, it has exploded 2"

	export MDU_LOG_LEVEL=info
	log_debug "Set steam aperture off 3" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_info "Working in closed environment 3" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[INFO] Working in closed environment 3" ""
	log_warn "OMG, it's heating 3" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[WARN] OMG, it's heating 3"
	log_error "Oops, it has exploded 3" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] Oops, it has exploded 3"
}

testMduLogLevelHasPrecedenceOverLogLevelEnvVar() {
	export MDU_LOG_LEVEL=debug
	export LOG_LEVEL=error
	log_debug "Set steam aperture off" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[DEBUG] Set steam aperture off" ""
	log_info "Working in closed environment" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[INFO] Working in closed environment" ""
	log_warn "OMG, it's heating" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[WARN] OMG, it's heating"
	log_error "Oops, it has exploded" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] Oops, it has exploded"

	export MDU_LOG_LEVEL=
	export LOG_LEVEL=error
	log_debug "Set steam aperture off 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_info "Working in closed environment 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_warn "OMG, it's heating 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" ""
	log_error "Oops, it has exploded 2" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] Oops, it has exploded 2"
}

testAllLoggingWithTag() {
	export MDU_LOG_TAG="[My Logs]"
	export MDU_LOG_LEVEL=debug
	log_debug "Set steam aperture off" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[DEBUG] [My Logs] Set steam aperture off" ""
	log_info "Working in closed environment" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "[INFO] [My Logs] Working in closed environment" ""
	log_warn "OMG, it's heating" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[WARN] [My Logs] OMG, it's heating"
	log_error "Oops, it has exploded" > "$TMP_DIR/text_out" 2> "$TMP_DIR/text_err"
	_assertOutput "" "[ERROR] [My Logs] Oops, it has exploded"
}




. "$test_root_dir/shunit2-2.0.3/src/shell/shunit2"
[ $__shunit_testsFailed -gt 0 ] && exit 5 || exit 0

