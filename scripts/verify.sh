#!/usr/bin/env bash
set -euo pipefail
task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lantern_godot="${GODOT_BIN:-godot}"
lantern_log="$(mktemp)"
trap 'rm -f "$lantern_log"' EXIT
run_godot() {
    "$lantern_godot" "$@" 2>&1 | tee "$lantern_log"
    # Godot can report runtime errors while returning zero. Treat them as failures.
    if grep -Eq '^(ERROR|SCRIPT ERROR):' "$lantern_log"; then
        return 1
    fi
}
run_godot --headless --editor --path "$task_root" --import
run_godot --headless --fixed-fps 60 --path "$task_root" tests/test_runner.tscn
run_godot --headless --fixed-fps 60 --path "$task_root" tests/navigation.tscn
run_godot --headless --fixed-fps 60 --path "$task_root" tests/traversal.tscn
