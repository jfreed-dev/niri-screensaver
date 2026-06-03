#!/usr/bin/env bats
# Unit tests for the inner driver's pure functions (bin/niri-screensaver).
# Run with `bats test/` or `make unit`.

setup() {
    load test_helper
    TEST_TMP="$(mktemp -d)"
    source_driver
}

teardown() {
    rm -rf "$TEST_TMP"
}

# ---------- build_effect_args ----------

@test "build_effect_args: defaults to --exclude-effects dev_worm" {
    INCLUDE_EFFECTS=""
    EXCLUDE_EFFECTS="dev_worm"
    run build_effect_args
    [ "$status" -eq 0 ]
    [ "$output" = "--exclude-effects dev_worm" ]
}

@test "build_effect_args: empty when neither include nor exclude is set" {
    INCLUDE_EFFECTS=""
    EXCLUDE_EFFECTS=""
    run build_effect_args
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "build_effect_args: INCLUDE_EFFECTS wins over EXCLUDE_EFFECTS" {
    INCLUDE_EFFECTS="beams,rain"
    EXCLUDE_EFFECTS="dev_worm"
    run build_effect_args
    [ "$status" -eq 0 ]
    [ "$output" = "--include-effects beams rain" ]
}

@test "build_effect_args: turns commas into spaces in exclude list" {
    INCLUDE_EFFECTS=""
    EXCLUDE_EFFECTS="dev_worm,burn"
    run build_effect_args
    [ "$output" = "--exclude-effects dev_worm burn" ]
}

# ---------- load_config ----------

@test "load_config: restores LOGO_FILE default when config writes a blank" {
    local cfg="$TEST_TMP/config"
    echo 'LOGO_FILE=""' > "$cfg"
    CONFIG_FILE="$cfg"
    SCREENSAVER_DIR="/tmp/ss-test"
    load_config
    [ "$LOGO_FILE" = "/tmp/ss-test/logo.txt" ]
}

@test "load_config: sanitizes a non-positive MIRROR_INTERVAL to 8" {
    local cfg="$TEST_TMP/config"
    echo 'MIRROR_INTERVAL="0"' > "$cfg"
    CONFIG_FILE="$cfg"
    load_config
    [ "$MIRROR_INTERVAL" = "8" ]
}

@test "load_config: keeps a valid MIRROR_INTERVAL" {
    local cfg="$TEST_TMP/config"
    echo 'MIRROR_INTERVAL="12"' > "$cfg"
    CONFIG_FILE="$cfg"
    load_config
    [ "$MIRROR_INTERVAL" = "12" ]
}

@test "load_config: no-op when config file is absent" {
    CONFIG_FILE="$TEST_TMP/does-not-exist"
    run load_config
    [ "$status" -eq 0 ]
}

# ---------- logo resolution ----------

@test "resolve_logo_dir: prefers an explicit LOGO_DIR that exists" {
    mkdir -p "$TEST_TMP/logos"
    LOGO_DIR="$TEST_TMP/logos"
    run resolve_logo_dir
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_TMP/logos" ]
}

@test "resolve_default_logo: returns the first existing candidate" {
    local f="$TEST_TMP/logo.txt"
    : > "$f"
    DEFAULT_LOGO_CANDIDATES=("$TEST_TMP/missing.txt" "$f")
    run resolve_default_logo
    [ "$status" -eq 0 ]
    [ "$output" = "$f" ]
}

@test "resolve_default_logo: fails when no candidate exists" {
    DEFAULT_LOGO_CANDIDATES=("$TEST_TMP/a.txt" "$TEST_TMP/b.txt")
    run resolve_default_logo
    [ "$status" -ne 0 ]
}

@test "pick_random_logo: returns a .txt from the resolved logo dir" {
    local d="$TEST_TMP/logos"
    mkdir -p "$d"
    : > "$d/a.txt"
    : > "$d/b.txt"
    LOGO_DIR="$d"
    run pick_random_logo
    [ "$status" -eq 0 ]
    [[ "$output" == "$d/"*.txt ]]
}

@test "pick_random_logo: fails when the logo dir has no .txt files" {
    local d="$TEST_TMP/empty"
    mkdir -p "$d"
    LOGO_DIR="$d"
    run pick_random_logo
    [ "$status" -ne 0 ]
}
