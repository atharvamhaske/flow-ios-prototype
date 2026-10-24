#!/bin/sh
set -eu
cd "$(dirname "$0")"
build_dir="${TMPDIR:-/tmp}/flow-checks"
mkdir -p "$build_dir"
xcrun swiftc -module-cache-path "$build_dir/cache" Flow/AmountInput.swift Checks/AmountChecks.swift -o "$build_dir/checks"
"$build_dir/checks"
xcrun swiftc -swift-version 6 -target arm64-apple-macosx14.0 -module-cache-path "$build_dir/cache" Flow/*.swift -o "$build_dir/Flow"
printf 'PASS: native macOS compilation\n'
