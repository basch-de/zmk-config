#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)

keymap="$repo_root/config/sofle_choc_pro.keymap"
layout="$repo_root/config/sofle_choc_pro.json"
output="$repo_root/output/pdf/sofle_choc_pro_keymap.pdf"
work_dir="$repo_root/tmp/keymap-pdf"
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
    "$output" \
    "$preview_dir"

printf 'Preview: %s\n' "$preview_dir"
