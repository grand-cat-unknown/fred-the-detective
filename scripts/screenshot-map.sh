#!/bin/bash
# Render the painted area of scenes/world/world_map.tscn to a PNG.
#
# Usage:
#   scripts/screenshot-map.sh                    # writes map_screenshot.png at project root
#   scripts/screenshot-map.sh path/to/out.png    # custom output path (absolute or project-relative)
set -euo pipefail
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-$HOME/Apps/Godot_v4.6.2-stable_linux.x86_64}"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot binary not found or not executable: $GODOT_BIN" >&2
  echo "Set GODOT_BIN env var to override." >&2
  exit 1
fi

OUTPUT_ARG=""
if [[ $# -ge 1 ]]; then
  case "$1" in
    /*) OUTPUT_PATH="$1" ;;
    res://*) OUTPUT_PATH="$1" ;;
    *)  OUTPUT_PATH="$PROJECT_DIR/$1" ;;
  esac
  OUTPUT_ARG="--output=$OUTPUT_PATH"
fi

cd "$PROJECT_DIR"
exec "$GODOT_BIN" --path "$PROJECT_DIR" res://scenes/tools/screenshot_map.tscn ++ $OUTPUT_ARG
