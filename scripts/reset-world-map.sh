#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: scripts/reset-world-map.sh [options]

Restores the world map scene and the interior TileSet to known-good versions.
Use this when Godot accidentally shifts, rotates, or hollows out the map data.

Options:
  --dry-run       Show what would be restored without changing files.
  --export        Re-export the Godot web build after the reset.
  -h, --help      Show this help text.
EOF
}

dry_run=false
run_export=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run)
			dry_run=true
			shift
			;;
		--export)
			run_export=true
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			usage >&2
			exit 1
			;;
	esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

cd "$repo_root"

map_ref="b532477acb6da578e7b7b4e95726dbb44eb30875"
tileset_ref="84c45a9b72ccb3ac15030af0c10aeb2957b433ed"
map_path="scenes/world/world_map.tscn"
tileset_path="assets/tile_sets/interiors-actual.tres"

require_ref_path() {
	local ref="$1"
	local path="$2"

	if ! git cat-file -e "$ref:$path" 2>/dev/null; then
		echo "Missing reset source: $ref:$path" >&2
		exit 1
	fi
}

show_local_changes() {
	local path="$1"

	if ! git diff --quiet -- "$path"; then
		echo "- $path has local changes and will be overwritten."
	fi
}

restore_from_ref() {
	local ref="$1"
	local path="$2"

	echo "Restoring $path from ${ref:0:12}"
	git restore --source="$ref" -- "$path"
}

require_ref_path "$map_ref" "$map_path"
require_ref_path "$tileset_ref" "$tileset_path"

echo "World map reset target:"
echo "- $map_path <- ${map_ref:0:12}"
echo "- $tileset_path <- ${tileset_ref:0:12}"

changed_paths="$(git diff --name-only -- "$map_path" "$tileset_path")"
if [[ -n "$changed_paths" ]]; then
	echo
	echo "Pending local changes in reset files:"
	show_local_changes "$map_path"
	show_local_changes "$tileset_path"
fi

if [[ "$dry_run" == true ]]; then
	echo
	echo "Dry run only. No files changed."
	exit 0
fi

echo
restore_from_ref "$map_ref" "$map_path"
restore_from_ref "$tileset_ref" "$tileset_path"

if [[ "$run_export" == true ]]; then
	echo
	"$script_dir/export-web.sh"
fi

echo
echo "World map reset complete."
