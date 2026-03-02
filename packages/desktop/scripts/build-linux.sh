#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT_DIR" ]]; then
  ROOT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
fi
DESKTOP_DIR="$ROOT_DIR/packages/desktop"
CLI_DIR="$ROOT_DIR/packages/opencode"
TAURI_DIR="$DESKTOP_DIR/src-tauri"
SIDECAR_DIR="$TAURI_DIR/sidecars"
BUILD_STAMP="$(mktemp -t opencode-linux-build.XXXXXX)"

TARGET_TRIPLE="${TARGET_TRIPLE:-x86_64-unknown-linux-gnu}"
SIDECAR_BASENAME="${SIDECAR_BASENAME:-opencode-cli}"
OUTPUT_DIR="${OUTPUT_DIR:-$DESKTOP_DIR/dist/deb}"

CLI_BUILD_CMD="${CLI_BUILD_CMD:-bun run script/build.ts --single}"
FRONTEND_BUILD_CMD="${FRONTEND_BUILD_CMD:-bun run build}"
TAURI_CMD="${TAURI_CMD:-bun tauri}"

LOW_MEMORY="${LOW_MEMORY:-0}"
SKIP_DEP_CHECK=0
INSTALL_DEPS="${INSTALL_DEPS:-0}"

info() { printf "\033[1;34m[INFO]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[WARN]\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m[ERR ]\033[0m %s\n" "$*" >&2; }
step() { printf "\n\033[1;36m==> %s\033[0m\n" "$*"; }

die() {
  err "$*"
  exit 1
}
trap 'rm -f "$BUILD_STAMP"' EXIT

on_err() {
  local code="$?"
  err "构建失败（exit=${code}）"
  err "失败行号: $1"
  err "失败命令: $2"
  err "请根据上方日志修复后重试。"
  exit "$code"
}
trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --target <triple>      Rust target triple (default: ${TARGET_TRIPLE})
  --low-memory           低内存模式（等价于 LOW_MEMORY=1）
  --skip-deps-check      跳过依赖检查
  --install-deps         先执行 bun install
  -h, --help             显示帮助

Env:
  TARGET_TRIPLE          目标架构（默认 x86_64-unknown-linux-gnu）
  CLI_BUILD_CMD          CLI 构建命令（默认: bun run script/build.ts --single）
  FRONTEND_BUILD_CMD     前端构建命令（默认: bun run build）
  TAURI_CMD              Tauri 命令（默认: bun tauri）
  CLI_BIN                指定 CLI 可执行文件路径（可选）
  SIDECAR_BASENAME       sidecar 基础名（默认: opencode-cli）
  OUTPUT_DIR             输出目录（默认: packages/desktop/dist/deb）
EOF
}

check_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  command -v "$cmd" >/dev/null 2>&1 && return 0
  err "缺少依赖命令: $cmd"
  [[ -n "$hint" ]] && err "安装建议: $hint"
  exit 1
}

check_tauri_cli() {
  if bun tauri --version >/dev/null 2>&1; then
    return 0
  fi
  warn "无法执行 Tauri CLI，将在构建时尝试。如果失败，请运行: bun install"
  return 0
}

check_target_host() {
  local host
  host="$(uname -m)"
  if [[ "$TARGET_TRIPLE" == "x86_64-unknown-linux-gnu" && "$host" != "x86_64" ]]; then
    warn "当前主机架构为 $host，目标为 $TARGET_TRIPLE；若未配置交叉编译，可能失败。"
  fi
}

check_linux_gui_deps() {
  if ! command -v pkg-config >/dev/null 2>&1; then
    warn "未安装 pkg-config，跳过 Linux GUI 依赖检查。"
    return 0
  fi

  local missing=()
  pkg-config --exists gtk+-3.0 || missing+=("gtk+-3.0")
  pkg-config --exists webkit2gtk-4.1 || pkg-config --exists webkit2gtk-4.0 || missing+=("webkit2gtk-4.1/4.0")
  pkg-config --exists javascriptcoregtk-4.1 || pkg-config --exists javascriptcoregtk-4.0 || missing+=("javascriptcoregtk-4.1/4.0")
  pkg-config --exists libsoup-3.0 || pkg-config --exists libsoup-2.4 || missing+=("libsoup-3.0/2.4")

  if [[ "${#missing[@]}" -eq 0 ]]; then
    return 0
  fi

  err "缺少 Linux 桌面构建依赖: ${missing[*]}"
  err "Debian/Ubuntu 可尝试："
  err "  sudo apt-get install -y libgtk-3-dev libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev libsoup-3.0-dev"
  err "旧版发行版可改用 4.0 / libsoup2.4 对应包。"
  exit 1
}


find_cli_bin() {
  if [[ -n "${CLI_BIN:-}" ]]; then
    [[ -f "$CLI_BIN" ]] || die "CLI_BIN 不存在: $CLI_BIN"
    echo "$CLI_BIN"
    return 0
  fi

  local candidates=(
    "$CLI_DIR/dist/opencode-linux-x64/bin/opencode"
    "$CLI_DIR/dist/opencode"
    "$CLI_DIR/bin/opencode"
  )

  local file
  for file in "${candidates[@]}"; do
    [[ -f "$file" ]] && [[ -x "$file" ]] || continue
    echo "$file"
    return 0
  done

  return 1
}

collect_debs() {
  local dir_target="$TAURI_DIR/target/$TARGET_TRIPLE/release/bundle/deb"
  local dir_default="$TAURI_DIR/target/release/bundle/deb"

  if [[ -d "$dir_target" ]]; then
    find "$dir_target" -maxdepth 1 -type f -name "*.deb" 2>/dev/null | sort
  fi
  if [[ -d "$dir_default" ]]; then
    find "$dir_default" -maxdepth 1 -type f -name "*.deb" 2>/dev/null | sort
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      [[ $# -ge 2 ]] || die "--target 需要参数"
      TARGET_TRIPLE="$2"
      shift 2
      ;;
    --low-memory)
      LOW_MEMORY=1
      shift
      ;;
    --skip-deps-check)
      SKIP_DEP_CHECK=1
      shift
      ;;
    --install-deps)
      INSTALL_DEPS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "未知参数: $1"
      ;;
  esac
done

[[ "$(uname -s)" == "Linux" ]] || die "该脚本仅支持 Linux"

[[ -d "$DESKTOP_DIR" ]] || die "未找到目录: $DESKTOP_DIR"
[[ -d "$CLI_DIR" ]] || die "未找到目录: $CLI_DIR"
[[ -d "$TAURI_DIR" ]] || die "未找到目录: $TAURI_DIR"

if [[ "$SKIP_DEP_CHECK" == "0" ]]; then
  step "依赖检查"
  check_cmd bun "安装 Bun: curl -fsSL https://bun.sh/install | bash"
  check_cmd cargo "安装 Rust: curl https://sh.rustup.rs -sSf | sh"
  check_cmd rustup "安装 Rust: curl https://sh.rustup.rs -sSf | sh"
  check_cmd dpkg-deb "Debian/Ubuntu: sudo apt-get install -y dpkg-dev"
  check_cmd fakeroot "Debian/Ubuntu: sudo apt-get install -y fakeroot"
  check_cmd pkg-config "Debian/Ubuntu: sudo apt-get install -y pkg-config"
  check_tauri_cli
  check_target_host
  check_linux_gui_deps
  command -v strip >/dev/null 2>&1 || warn "未找到 strip，体积优化可能受影响（可安装 binutils）"
fi

if [[ "$LOW_MEMORY" == "1" ]]; then
  step "启用低内存模式"
  export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-1}"
  export CARGO_INCREMENTAL=0
  export CARGO_PROFILE_RELEASE_CODEGEN_UNITS="${CARGO_PROFILE_RELEASE_CODEGEN_UNITS:-1}"
  export RUSTFLAGS="${RUSTFLAGS:+$RUSTFLAGS }-Ccodegen-units=1 -Cdebuginfo=0"
  info "CARGO_BUILD_JOBS=${CARGO_BUILD_JOBS}"
  info "CARGO_INCREMENTAL=${CARGO_INCREMENTAL}"
fi

step "检查 Rust target"
if ! rustup target list --installed | grep -qx "$TARGET_TRIPLE"; then
  info "安装 target: $TARGET_TRIPLE"
  rustup target add "$TARGET_TRIPLE"
else
  info "已安装 target: $TARGET_TRIPLE"
fi

if [[ "$INSTALL_DEPS" == "1" ]]; then
  step "安装项目依赖"
  (
    cd "$ROOT_DIR"
    bun install
  )
fi

step "1/4 构建 opencode CLI"
(
  cd "$CLI_DIR"
  eval "$CLI_BUILD_CMD"
)

step "2/4 复制 CLI 到 sidecars"
cli_bin="$(find_cli_bin || true)"
[[ -n "$cli_bin" ]] || die "未找到 CLI 可执行文件。可通过 CLI_BIN 指定路径。"

mkdir -p "$SIDECAR_DIR"
sidecar_bin="$SIDECAR_DIR/${SIDECAR_BASENAME}-${TARGET_TRIPLE}"
cp -f "$cli_bin" "$sidecar_bin"
chmod +x "$sidecar_bin"
info "CLI 来源: $cli_bin"
info "Sidecar 输出: $sidecar_bin"

step "3/4 构建前端"
(
  cd "$DESKTOP_DIR"
  eval "$FRONTEND_BUILD_CMD"
)

step "4/4 构建 Tauri deb"
touch "$BUILD_STAMP"
(
  cd "$DESKTOP_DIR"
  eval "$TAURI_CMD build --target $TARGET_TRIPLE --bundles deb"
)

step "收集 deb 产物"
mapfile -t debs < <(
  collect_debs | while IFS= read -r file; do
    [[ -n "$file" && "$file" -nt "$BUILD_STAMP" ]] && printf '%s\n' "$file"
  done | sort -u
)
if [[ "${#debs[@]}" -eq 0 ]]; then
  warn "未检测到本次新增 .deb，回退为读取当前目录中的 .deb 产物（可能包含旧文件）。"
  mapfile -t debs < <(collect_debs | sort -u)
fi

[[ "${#debs[@]}" -gt 0 ]] || die "未找到 .deb 产物，请检查 Tauri 构建日志与 tauri.conf"

mkdir -p "$OUTPUT_DIR"
copied=()
for deb in "${debs[@]}"; do
  name="$(basename "$deb")"
  cp -f "$deb" "$OUTPUT_DIR/$name"
  copied+=("$OUTPUT_DIR/$name")
done

printf "\n\033[1;32m✅ Debian 包构建完成\033[0m\n"
printf "Target: %s\n" "$TARGET_TRIPLE"
printf "Sidecar: %s\n" "$sidecar_bin"
printf "Output: %s\n" "$OUTPUT_DIR"
for file in "${copied[@]}"; do
  printf " - %s\n" "$file"
done
