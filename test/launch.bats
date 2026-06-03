#!/usr/bin/env bats
# Unit tests for the launcher's pure functions (bin/niri-screensaver-launch).
# Run with `bats test/` or `make unit`.

setup() {
    load test_helper
    TEST_TMP="$(mktemp -d)"
    export CONFIG_DIR="$TEST_TMP/cfg"
    mkdir -p "$CONFIG_DIR"
    source_launcher
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ---------- toggle state ----------

@test "is_disabled: false when the toggle file is absent" {
    run is_disabled
    [ "$status" -ne 0 ]
}

@test "is_disabled: true when the toggle file is present" {
    touch "$TOGGLE_FILE"
    run is_disabled
    [ "$status" -eq 0 ]
}

# ---------- kill debounce (issue #4) ----------

@test "kill_too_soon_after_launch: true immediately after a launch stamp" {
    KILL_DEBOUNCE_SECS=3
    date +%s > "$LAUNCH_STAMP_FILE"
    run kill_too_soon_after_launch
    [ "$status" -eq 0 ]
}

@test "kill_too_soon_after_launch: false when the stamp is older than the window" {
    KILL_DEBOUNCE_SECS=3
    echo $(( $(date +%s) - 100 )) > "$LAUNCH_STAMP_FILE"
    run kill_too_soon_after_launch
    [ "$status" -ne 0 ]
}

@test "kill_too_soon_after_launch: false when debounce is disabled (0)" {
    KILL_DEBOUNCE_SECS=0
    date +%s > "$LAUNCH_STAMP_FILE"
    run kill_too_soon_after_launch
    [ "$status" -ne 0 ]
}

@test "kill_too_soon_after_launch: false when no stamp file exists" {
    KILL_DEBOUNCE_SECS=3
    run kill_too_soon_after_launch
    [ "$status" -ne 0 ]
}

# ---------- battery gating ----------

@test "should_skip_for_battery: false when threshold is 0 (disabled)" {
    BATTERY_MIN_PERCENT=0
    run should_skip_for_battery
    [ "$status" -ne 0 ]
}

@test "should_skip_for_battery: false when threshold is not an integer" {
    BATTERY_MIN_PERCENT=abc
    run should_skip_for_battery
    [ "$status" -ne 0 ]
}

# ---------- mirror-mode argument assembly ----------

@test "mirror_logo_dir: prefers an explicit LOGO_DIR that exists" {
    local d="$TEST_TMP/logos"
    mkdir -p "$d"
    LOGO_DIR="$d"
    run mirror_logo_dir
    [ "$status" -eq 0 ]
    [ "$output" = "$d" ]
}

@test "pick_one_logo: returns a .txt path from the logo dir" {
    local d="$TEST_TMP/logos"
    mkdir -p "$d"
    : > "$d/x.txt"
    LOGO_DIR="$d"
    run pick_one_logo
    [ "$status" -eq 0 ]
    [ "$output" = "$d/x.txt" ]
}

@test "setup_mirror_args: leaves DRIVER_ARGS empty in independent mode" {
    MULTI_MONITOR_MODE=independent
    DRIVER_ARGS=(sentinel)
    setup_mirror_args
    [ "${#DRIVER_ARGS[@]}" -eq 0 ]
}

@test "setup_mirror_args: adds a numeric --seed in mirror mode" {
    MULTI_MONITOR_MODE=mirror
    RANDOM_LOGO=false
    setup_mirror_args
    [ "${DRIVER_ARGS[0]}" = "--seed" ]
    [[ "${DRIVER_ARGS[1]}" =~ ^[0-9]+$ ]]
}

# ---------- data-dir resolution ----------

@test "resolve_data_dir: finds the dir containing alacritty-screensaver.toml" {
    local d="$TEST_TMP/data"
    mkdir -p "$d"
    : > "$d/alacritty-screensaver.toml"
    DATA_CANDIDATES=("$TEST_TMP/none" "$d")
    run resolve_data_dir
    [ "$status" -eq 0 ]
    [ "$output" = "$d" ]
}
