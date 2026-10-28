#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

usage() {
    printf 'Usage: %s [sofle_choc_pro|corne_choc_pro|all]\n' "$0" >&2
}

if [ "$#" -gt 1 ]; then
    usage
    exit 2
fi

target=${1:-sofle_choc_pro}

if [ "$target" = all ]; then
    "$0" sofle_choc_pro
    "$0" corne_choc_pro
    exit 0
fi

case "$target" in
    sofle_choc_pro)
        layout_name=default_layout
        expected_layers=7
        expected_keys=60
        omitted_positions=
        ;;
    corne_choc_pro)
        layout_name=default_layout
        expected_layers=9
        expected_keys=46
        omitted_positions=6,7,20,21
        ;;
    *)
        printf 'Unknown keyboard target: %s\n' "$target" >&2
        usage
        exit 2
        ;;
esac

keymap="$repo_root/config/$target.keymap"
layout="$repo_root/config/$target.json"
output="$repo_root/output/pdf/${target}_keymap.pdf"
work_dir="$repo_root/tmp/keymap-pdf/$target"
preview_dir="$work_dir/rendered"
module_cache="$work_dir/module-cache"

sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [ ! -d "$sdk" ]; then
    sdk=$(xcrun --sdk macosx --show-sdk-path)
fi

mkdir -p "$preview_dir" "$module_cache" "$(dirname -- "$output")"

swift \
    -sdk "$sdk" \
    -module-cache-path "$module_cache" \
    "$script_dir/generate.swift" \
    "$keymap" \
    "$layout" \
    "$layout_name" \
    "$expected_layers" \
    "$expected_keys" \
    "$omitted_positions" \
    "$output" \
    "$preview_dir"

printf 'Preview: %s\n' "$preview_dir"
