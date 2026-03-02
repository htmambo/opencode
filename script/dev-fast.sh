#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$script_dir/.." && pwd)"
action="${1:-all}"

run() {
  printf '+ %s\n' "$*"
  "$@"
}

usage() {
  cat <<'EOF'
Usage: script/dev-fast.sh [all|sync|check|push]

  all    同步 origin/dev + 快速校验 + 全量 typecheck（默认）
  sync   仅同步 origin/dev 到当前分支
  check  仅执行快速校验 + 全量 typecheck
  push   执行 all 后推送当前分支到 origin
EOF
}

ensure_clean() {
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "工作区有未提交改动，请先提交或暂存后再执行。"
    git status --short
    exit 1
  fi
}

sync_dev() {
  run git fetch origin dev
  local branch
  branch="$(git branch --show-current)"
  if [[ -z "$branch" ]]; then
    echo "当前处于 detached HEAD，无法自动同步 dev。"
    exit 1
  fi

  if [[ "$branch" == "dev" ]]; then
    run git pull --ff-only origin dev
    return
  fi

  local behind ahead
  read -r behind ahead < <(git rev-list --left-right --count origin/dev...HEAD | tr '\t' ' ')
  if [[ "${behind:-0}" == "0" ]]; then
    echo "当前分支已包含 origin/dev 的最新提交。"
    return
  fi

  echo "同步 dev：当前分支落后 $behind 个提交，领先 $ahead 个提交。"
  run git merge --no-ff origin/dev
}

fast_check() {
  mapfile -t files < <(git diff --name-only origin/dev...HEAD)

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "当前分支与 origin/dev 无差异，跳过快速校验。"
    return
  fi

  local app=0
  local ui=0
  local core=0
  local sdk=0

  for f in "${files[@]}"; do
    case "$f" in
      packages/app/*) app=1 ;;
      packages/ui/*) ui=1 ;;
      packages/opencode/*) core=1 ;;
      packages/sdk/js/*) sdk=1 ;;
    esac
  done

  if [[ "$ui" == "1" ]]; then
    run bun run --cwd packages/ui typecheck
  fi

  if [[ "$app" == "1" ]]; then
    run bun run --cwd packages/app typecheck
    run bun run --cwd packages/app test:unit
  fi

  if [[ "$core" == "1" ]]; then
    run bun run --cwd packages/opencode typecheck
  fi

  if [[ "$sdk" == "1" ]]; then
    run bun run --cwd packages/sdk/js typecheck
  fi

  if [[ "$app" == "0" && "$ui" == "0" && "$core" == "0" && "$sdk" == "0" ]]; then
    echo "未命中 app/ui/opencode/sdk 目录，跳过快速校验。"
  fi
}

full_check() {
  run bun typecheck
}

push_branch() {
  run git push origin HEAD
}

main() {
  cd "$root"

  case "$action" in
    sync)
      ensure_clean
      sync_dev
      ;;
    check)
      fast_check
      full_check
      ;;
    all)
      ensure_clean
      sync_dev
      fast_check
      full_check
      ;;
    push)
      ensure_clean
      sync_dev
      fast_check
      full_check
      push_branch
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
