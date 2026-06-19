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

# ---------- mirror auto-derive: geometry math (#24) ----------

@test "mirror_extent: per-dimension min and max across mismatched outputs" {
    output="$(printf 'eDP-1\t1440\t960\nDP-2\t3840\t2160\n' | mirror_extent)"
    [ "$output" = "1440 960 3840 2160" ]
}

@test "mirror_extent: equal min and max for matched outputs" {
    output="$(printf 'a\t1920\t1080\nb\t1920\t1080\n' | mirror_extent)"
    [ "$output" = "1920 1080 1920 1080" ]
}

@test "mirror_extent: skips lines whose geometry is not numeric" {
    output="$(printf 'good\t1000\t800\nbad\tnull\tnull\n' | mirror_extent)"
    [ "$output" = "1000 800 1000 800" ]
}

@test "mirror_extent: empty when no line has numeric geometry" {
    output="$(printf 'bad\tx\ty\n' | mirror_extent)"
    [ -z "$output" ]
}

# ---------- mirror auto-derive: cell-metrics cache (#24) ----------

@test "read_cell_metrics: succeeds on four positive integers" {
    CELL_METRICS_FILE="$TEST_TMP/cells"
    printf 'CELL_REF_LOGICAL_W=1440\nCELL_REF_COLS=180\nCELL_REF_LOGICAL_H=960\nCELL_REF_ROWS=50\n' > "$CELL_METRICS_FILE"
    run read_cell_metrics
    [ "$status" -eq 0 ]
}

@test "read_cell_metrics: fails when the cache file is missing" {
    CELL_METRICS_FILE="$TEST_TMP/absent"
    run read_cell_metrics
    [ "$status" -ne 0 ]
}

@test "read_cell_metrics: fails on a partial or garbage cache" {
    CELL_METRICS_FILE="$TEST_TMP/cells"
    printf 'CELL_REF_LOGICAL_W=1440\nCELL_REF_COLS=oops\n' > "$CELL_METRICS_FILE"
    run read_cell_metrics
    [ "$status" -ne 0 ]
}

@test "derive_mirror_canvas: smallest output maps to its own exact grid" {
    CELL_METRICS_FILE="$TEST_TMP/cells"
    printf 'CELL_REF_LOGICAL_W=1440\nCELL_REF_COLS=180\nCELL_REF_LOGICAL_H=960\nCELL_REF_ROWS=50\n' > "$CELL_METRICS_FILE"
    run derive_mirror_canvas 1440 960
    [ "$status" -eq 0 ]
    [ "$output" = "180 50" ]
}

@test "derive_mirror_canvas: floors when the reference output is larger" {
    CELL_METRICS_FILE="$TEST_TMP/cells"
    printf 'CELL_REF_LOGICAL_W=1920\nCELL_REF_COLS=240\nCELL_REF_LOGICAL_H=1080\nCELL_REF_ROWS=56\n' > "$CELL_METRICS_FILE"
    # 1440*240/1920 = 180 ; 960*56/1080 = 49.7 -> floor 49
    run derive_mirror_canvas 1440 960
    [ "$status" -eq 0 ]
    [ "$output" = "180 49" ]
}

@test "derive_mirror_canvas: fails without a usable cache" {
    CELL_METRICS_FILE="$TEST_TMP/absent"
    run derive_mirror_canvas 1440 960
    [ "$status" -ne 0 ]
}

# ---------- mirror auto-derive: logo fit + orchestration (#24) ----------

@test "logo_dimensions: widest line length and line count" {
    local f="$TEST_TMP/logo.txt"
    printf 'abc\nabcdefgh\nxy\n' > "$f"
    run logo_dimensions "$f"
    [ "$status" -eq 0 ]
    [ "$output" = "8 3" ]
}

@test "setup_mirror_canvas: no-op in independent mode" {
    MULTI_MONITOR_MODE=independent
    DRIVER_ARGS=()
    setup_mirror_canvas
    [ "${#DRIVER_ARGS[@]}" -eq 0 ]
    [ -z "$MEASURE_OUTPUT" ]
}

@test "setup_mirror_canvas: explicit MIRROR_CANVAS dims suppress auto-derive" {
    MULTI_MONITOR_MODE=mirror
    MIRROR_CANVAS_COLS=86
    MIRROR_CANVAS_ROWS=49
    DRIVER_ARGS=()
    setup_mirror_canvas
    [ "${#DRIVER_ARGS[@]}" -eq 0 ]
    [ -z "$MEASURE_OUTPUT" ]
}

@test "setup_mirror_canvas: matched outputs keep the full-screen canvas" {
    MULTI_MONITOR_MODE=mirror
    MIRROR_CANVAS_COLS=""
    MIRROR_CANVAS_ROWS=""
    output_geometry() { printf 'a\t1920\t1080\nb\t1920\t1080\n'; }
    DRIVER_ARGS=()
    setup_mirror_canvas
    [ "${#DRIVER_ARGS[@]}" -eq 0 ]
    [ -z "$MEASURE_OUTPUT" ]
}

@test "setup_mirror_canvas: mismatched outputs append canvas args from cache" {
    MULTI_MONITOR_MODE=mirror
    MIRROR_CANVAS_COLS=""
    MIRROR_CANVAS_ROWS=""
    CELL_METRICS_FILE="$TEST_TMP/cells"
    printf 'CELL_REF_LOGICAL_W=1440\nCELL_REF_COLS=180\nCELL_REF_LOGICAL_H=960\nCELL_REF_ROWS=50\n' > "$CELL_METRICS_FILE"
    output_geometry() { printf 'eDP-1\t1440\t960\nDP-2\t3840\t2160\n'; }
    DRIVER_ARGS=()
    setup_mirror_canvas
    [ "${DRIVER_ARGS[0]}" = "--mirror-canvas-cols" ]
    [ "${DRIVER_ARGS[1]}" = "180" ]
    [ "${DRIVER_ARGS[2]}" = "--mirror-canvas-rows" ]
    [ "${DRIVER_ARGS[3]}" = "50" ]
    [ "$MEASURE_OUTPUT" = "eDP-1" ]
    [ "$MEASURE_GEOM" = "1440x960" ]
}

@test "setup_mirror_canvas: mismatched outputs without a cache only schedule measurement" {
    MULTI_MONITOR_MODE=mirror
    MIRROR_CANVAS_COLS=""
    MIRROR_CANVAS_ROWS=""
    CELL_METRICS_FILE="$TEST_TMP/absent"
    output_geometry() { printf 'eDP-1\t1440\t960\nDP-2\t3840\t2160\n'; }
    DRIVER_ARGS=()
    setup_mirror_canvas
    [ "${#DRIVER_ARGS[@]}" -eq 0 ]
    [ "$MEASURE_OUTPUT" = "eDP-1" ]
    [ "$MEASURE_GEOM" = "1440x960" ]
}
