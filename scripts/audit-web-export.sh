#!/usr/bin/env bash

set -euo pipefail

usage() {
	cat <<'EOF'
Usage: scripts/audit-web-export.sh [public-dir] [deployed-url]

Shows the files that will be publicly served by Vercel, their raw sizes,
estimated compressed sizes, and optional production response headers.

Arguments:
  public-dir      Directory Vercel serves as static public assets.
                  Default: public
  deployed-url    Optional deployed site URL to verify response headers.
EOF
}

human_bytes() {
	local bytes="$1"
	awk -v bytes="$bytes" 'BEGIN {
		split("B KiB MiB GiB", units, " ");
		value = bytes + 0;
		unit = 1;
		while (value >= 1024 && unit < 4) {
			value = value / 1024;
			unit++;
		}
		if (unit == 1) {
			printf "%d %s", value, units[unit];
		} else {
			printf "%.2f %s", value, units[unit];
		}
	}'
}

compressed_size() {
	local mode="$1"
	local file="$2"

	case "$mode" in
		gzip)
			gzip -9 -c "$file" | wc -c | tr -d '[:space:]'
			;;
		brotli)
			brotli -q 11 -c "$file" | wc -c | tr -d '[:space:]'
			;;
		*)
			return 1
			;;
	esac
}

public_dir="${1:-public}"
deployed_url="${2:-}"

if [[ "${public_dir:-}" == "-h" || "${public_dir:-}" == "--help" ]]; then
	usage
	exit 0
fi

if [[ ! -d "$public_dir" ]]; then
	echo "Missing public export directory: $public_dir" >&2
	exit 1
fi

if [[ -n "$deployed_url" ]]; then
	deployed_url="${deployed_url%/}"
fi

echo
echo "Public files exposed by Vercel from: $public_dir"
printf '%-38s %12s %12s' "file" "raw" "gzip -9"
if command -v brotli >/dev/null 2>&1; then
	printf ' %12s' "brotli -11"
fi
printf '\n'
printf '%-38s %12s %12s' "----" "---" "-------"
if command -v brotli >/dev/null 2>&1; then
	printf ' %12s' "----------"
fi
printf '\n'

total_raw=0
total_gzip=0
total_brotli=0

while IFS= read -r -d '' file; do
	relative="${file#$public_dir/}"
	raw_size="$(wc -c < "$file" | tr -d '[:space:]')"
	gzip_size="$(compressed_size gzip "$file")"

	total_raw=$((total_raw + raw_size))
	total_gzip=$((total_gzip + gzip_size))

	printf '%-38s %12s %12s' "$relative" "$(human_bytes "$raw_size")" "$(human_bytes "$gzip_size")"
	if command -v brotli >/dev/null 2>&1; then
		brotli_size="$(compressed_size brotli "$file")"
		total_brotli=$((total_brotli + brotli_size))
		printf ' %12s' "$(human_bytes "$brotli_size")"
	fi
	printf '\n'
done < <(find "$public_dir" -maxdepth 1 -type f -print0 | sort -z)

printf '%-38s %12s %12s' "TOTAL" "$(human_bytes "$total_raw")" "$(human_bytes "$total_gzip")"
if command -v brotli >/dev/null 2>&1; then
	printf ' %12s' "$(human_bytes "$total_brotli")"
fi
printf '\n'

echo
echo "Exposure notes:"
echo "- Only files under $public_dir are directly public static files."
echo "- Vercel serverless source lives in api/ and lib/ for runtime, but is not served as static content."
echo "- Godot source folders such as assets/, scenes/, and scripts/ are excluded from CLI upload by .vercelignore."

if find "$public_dir" -maxdepth 1 -type f -name '*.import' | grep -q .; then
	echo "- Warning: .import files are present in $public_dir; these are usually source/import metadata, not web runtime assets."
fi

if [[ -n "$deployed_url" ]]; then
	echo
	echo "Production header check:"
	for asset in index.html index.js index.wasm index.pck; do
		if [[ -f "$public_dir/$asset" ]]; then
			echo
			echo "$deployed_url/$asset"
			curl -sS -I -H 'Accept-Encoding: br,gzip' "$deployed_url/$asset" \
				| awk 'BEGIN { IGNORECASE=1 } /^(HTTP\/|content-type:|content-length:|content-encoding:|cache-control:|x-vercel-cache:|cross-origin-opener-policy:|cross-origin-embedder-policy:)/ { print }'
		fi
	done
fi
