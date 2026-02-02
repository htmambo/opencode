#!/bin/bash
set -e

# 设置 TMPDIR 到同一卷（解决跨挂载点卡住问题）
mkdir -p /Volumes/Workarea/tmp
export TMPDIR=/Volumes/Workarea/tmp

# 设置目标架构
export TAURI_ENV_TARGET_TRIPLE="x86_64-apple-darwin"
export RUST_TARGET="x86_64-apple-darwin"

# 检查是否启用低内存模式
LOW_MEMORY_MODE=0
for arg in "$@"; do
    if [ "$arg" = "--low-memory" ]; then
        LOW_MEMORY_MODE=1
        break
    fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

if [ $LOW_MEMORY_MODE -eq 1 ]; then
    echo "=== Low memory mode enabled ==="
    echo "Using single-threaded build with optimized flags"
    export CARGO_BUILD_JOBS=1
    export RUSTFLAGS="-C opt-level=z -C codegen-units=1"
fi

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

# 捕获 Tauri 构建错误
if ! bun tauri build --target "${RUST_TARGET}"; then
    exit_code=$?

    # 检查是否是资源不足错误
    if echo "$exit_code" | grep -q "35\|12" 2>/dev/null || [ $exit_code -eq 1 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  构建失败！检测到可能是资源不足的问题。"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        if [ $LOW_MEMORY_MODE -eq 0 ]; then
            echo "  请尝试使用低内存模式重试："
            echo ""
            echo "    $0 --low-memory"
            echo ""
            echo "  或先释放一些内存（关闭浏览器等应用），然后再试。"
        else
            echo "  低内存模式仍然失败，建议："
            echo "  1. 重启机器释放所有内存"
            echo "  2. 使用 GitHub Actions 构建"
            echo "  3. 在内存更大的机器上构建"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi

    exit $exit_code
fi

echo ""
echo "=== Build complete! ==="
echo "App bundle should be in: src-tauri/target/release/bundle/macos/"
