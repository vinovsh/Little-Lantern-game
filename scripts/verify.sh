#!/usr/bin/env bash
set -euo pipefail
task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lantern_godot="${GODOT_BIN:-godot}"
"$lantern_godot" --headless --editor --path "$task_root" --import
"$lantern_godot" --headless --fixed-fps 60 --path "$task_root" tests/test_runner.tscn
"$lantern_godot" --headless --fixed-fps 60 --path "$task_root" tests/traversal.tscn
