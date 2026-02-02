#!/bin/bash
set -e

# 设置 TMPDIR 到同一卷（解决跨挂载点卡住问题）
mkdir -p /Volumes/Workarea/tmp
export TMPDIR=/Volumes/Workarea/tmp

# 设置目标架构
export TAURI_ENV_TARGET_TRIPLE="x86_64-apple-darwin"
export RUST_TARGET="x86_64-apple-darwin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=== Step 1: Building opencode CLI ==="
cd ../opencode
# Skip install since it hangs on cross-mount point
bun run script/build.ts --single --skip-install
cd "$SCRIPT_DIR/.."

echo ""
echo "=== Step 2: Creating sidecars directory ==="
mkdir -p src-tauri/sidecars

echo ""
echo "=== Step 3: Copying CLI to sidecars ==="
cp ../opencode/dist/opencode-darwin-x64/bin/opencode "src-tauri/sidecars/opencode-cli-${RUST_TARGET}"
echo "Copied opencode CLI to sidecars/opencode-cli-${RUST_TARGET}"

echo ""
echo "=== Step 4: Building frontend ==="
bun run build

echo ""
echo "=== Step 5: Building Tauri app ==="
bun tauri build --target "${RUST_TARGET}"

echo ""
echo "=== Build complete! ==="
echo "App bundle should be in: src-tauri/target/release/bundle/macos/"
