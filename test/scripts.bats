#!/usr/bin/env bats
# Integration tests for the helper scripts and the ctl shim. These run the
# scripts as child processes (rather than sourcing them) so kcov records their
# coverage too. Run with `bats test/` or `make unit`.

setup() {
    load test_helper
}

# ---------- helper scripts (also CI gates) ----------

@test "json-validate.sh: passes on the repo tree" {
    run bash "$REPO_ROOT/scripts/json-validate.sh"
    [ "$status" -eq 0 ]
}

@test "check-doc-links.sh: passes on the repo tree" {
    run bash "$REPO_ROOT/scripts/check-doc-links.sh"
    [ "$status" -eq 0 ]
}

# ---------- ctl shim dispatch ----------

@test "ctl: help prints usage" {
    run "$CTL" help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "ctl: no argument defaults to help" {
    run "$CTL"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Commands:"* ]]
}

@test "ctl: unknown command exits non-zero with a hint" {
    run "$CTL" bogus-command
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}
