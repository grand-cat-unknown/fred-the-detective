#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: scripts/export-web.sh [options]

Exports the existing Godot Web preset from this project.

Options:
  --debug            Export a debug build instead of release.
  --no-clean         Do not clear the output directory before copying files.
  --skip-audit       Do not print the public export size/exposure audit.
  --preset NAME      Use a different export preset. Default: Web
  --output PATH      Write the HTML shell to a different path.
                     Default: public/index.html
  --godot PATH       Use a specific Godot executable.
  -h, --help         Show this help text.

Environment:
  GODOT              Path to the Godot executable to use.
EOF
}

require_value() {
	local option="$1"
	local value="${2:-}"
	if [[ -z "$value" || "$value" == --* ]]; then
		echo "Missing value for $option." >&2
		usage >&2
		exit 1
	fi
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
template_path="$script_dir/index.template.html"

mode="release"
preset="Web"
output="public/index.html"
clean_output=true
run_audit=true
godot_bin="${GODOT:-}"
godot_label=""
godot_cmd=()
godot_env=()

while [[ $# -gt 0 ]]; do
	case "$1" in
		--debug)
			mode="debug"
			shift
			;;
		--release)
			mode="release"
			shift
			;;
		--no-clean)
			clean_output=false
			shift
			;;
		--skip-audit)
			run_audit=false
			shift
			;;
		--preset)
			require_value "$1" "${2:-}"
			preset="$2"
			shift 2
			;;
		--output)
			require_value "$1" "${2:-}"
			output="$2"
			shift 2
			;;
		--godot)
			require_value "$1" "${2:-}"
			godot_bin="$2"
			shift 2
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

if [[ -n "$godot_bin" ]]; then
	godot_cmd=("$godot_bin")
	godot_label="$godot_bin"
else
	for candidate in godot4 godot godot4.6 Godot_v4; do
		if command -v "$candidate" >/dev/null 2>&1; then
			godot_cmd=("$candidate")
			godot_label="$candidate"
			break
		fi
	done

	if [[ ${#godot_cmd[@]} -eq 0 ]]; then
		shopt -s nullglob
		download_candidates=(
			"$project_root/../../Apps/Godot_v4.6.2-stable_linux.x86_64"
			"$project_root"/../../Apps/Godot*_linux.x86_64
			"$project_root"/../../Apps/Godot*.AppImage
			"$HOME/Apps/Godot_v4.6.2-stable_linux.x86_64"
			"$HOME"/Apps/Godot*_linux.x86_64
			"$HOME"/Apps/Godot*.AppImage
			"$HOME/Downloads/Godot_v4.6.2-stable_linux.x86_64"
			"$HOME"/Downloads/Godot*_linux.x86_64
			"$HOME"/Downloads/Godot*.AppImage
		)
		shopt -u nullglob

		for candidate in "${download_candidates[@]}"; do
			if [[ -x "$candidate" ]]; then
				godot_cmd=("$candidate")
				godot_label="$candidate"
				break
			fi
		done
	fi

	if [[ ${#godot_cmd[@]} -eq 0 ]] && command -v flatpak >/dev/null 2>&1; then
		for app_id in org.godotengine.Godot org.godotengine.GodotSharp; do
			if flatpak info "$app_id" >/dev/null 2>&1; then
				godot_cmd=(flatpak run "$app_id")
				godot_label="flatpak run $app_id"
				break
			fi
		done
	fi

	if [[ ${#godot_cmd[@]} -eq 0 ]]; then
		for snap_candidate in godot-4 godot4 godot; do
			if [[ -x "/snap/bin/$snap_candidate" ]]; then
				godot_cmd=("/snap/bin/$snap_candidate")
				godot_label="/snap/bin/$snap_candidate"
				break
			fi
		done
	fi
fi

if [[ ${#godot_cmd[@]} -eq 0 ]]; then
	echo "Could not find a Godot CLI." >&2
	echo "Set GODOT=/path/to/godot4, pass --godot /path/to/godot4, place a Godot AppImage in ~/Downloads, or install Godot in a detectable Flatpak/Snap location." >&2
	exit 1
fi

default_xdg_data_home="$HOME/.local/share"
current_xdg_data_home="${XDG_DATA_HOME:-$default_xdg_data_home}"
if [[ "$current_xdg_data_home" != "$default_xdg_data_home" ]] \
	&& [[ -d "$default_xdg_data_home/godot/export_templates" ]]; then
	godot_env=("XDG_DATA_HOME=$default_xdg_data_home")
fi

if [[ "$output" = /* ]]; then
	export_path="$output"
else
	export_path="$project_root/$output"
fi

output_dir="$(dirname "$export_path")"
mkdir -p "$output_dir"

if [[ ! -f "$template_path" ]]; then
	echo "Missing web shell template: $template_path" >&2
	exit 1
fi

audit_script="$script_dir/audit-web-export.sh"

case "$output_dir" in
	"$project_root"|"$HOME"|"/"|".")
		echo "Refusing to clean unsafe output directory: $output_dir" >&2
		exit 1
		;;
esac

staging_dir="$(mktemp -d)"
cleanup() {
	rm -rf "$staging_dir"
}
trap cleanup EXIT

staging_path="$staging_dir/$(basename "$export_path")"

echo "Using Godot executable: $godot_label"
if [[ ${#godot_env[@]} -gt 0 ]]; then
	echo "Using XDG_DATA_HOME override: $default_xdg_data_home"
fi
echo "Export preset: $preset"
echo "Export mode: $mode"
echo "Export path: $export_path"
echo "Staging path: $staging_path"

if [[ "$mode" == "debug" ]]; then
	env "${godot_env[@]}" "${godot_cmd[@]}" --headless --path "$project_root" --export-debug "$preset" "$staging_path"
else
	env "${godot_env[@]}" "${godot_cmd[@]}" --headless --path "$project_root" --export-release "$preset" "$staging_path"
fi

godot_config_line="$(grep -m1 '^const GODOT_CONFIG = ' "$staging_path" || true)"
godot_threads_line="$(grep -m1 '^const GODOT_THREADS_ENABLED = ' "$staging_path" || true)"

if [[ -z "$godot_config_line" || -z "$godot_threads_line" ]]; then
	echo "Could not find Godot config markers in exported HTML shell." >&2
	exit 1
fi

GODOT_CONFIG_LINE="$godot_config_line" GODOT_THREADS_LINE="$godot_threads_line" perl -0pe '
	s/__GODOT_CONFIG_LINE__/$ENV{GODOT_CONFIG_LINE}/g;
	s/__GODOT_THREADS_LINE__/$ENV{GODOT_THREADS_LINE}/g;
' "$template_path" > "$staging_path"

if [[ "$clean_output" == true ]]; then
	find "$output_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
fi

cp -a "$staging_dir"/. "$output_dir"/

echo "Export finished."

if [[ "$run_audit" == true && -x "$audit_script" ]]; then
	"$audit_script" "$output_dir"
fi
