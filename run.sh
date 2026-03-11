#!/usr/bin/env bash
# Build Rust SDK (incremental — only recompiles changed files) then run Flutter.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SDK_DIR="$SCRIPT_DIR/packages/dspatch_sdk"

echo "→ Building Rust SDK..."
(cd "$SDK_DIR" && cargo build --features flutter)

echo "→ Running Flutter app..."
cd "$SCRIPT_DIR"
flutter run -d windows "$@"
