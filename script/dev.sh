#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$script_dir/.." && pwd)"
pid_backend="$script_dir/opencode-backend.pid"
pid_web="$script_dir/opencode-web.pid"

action="${1:-start}"

is_running() {
  local pidfile="$1"
  [[ -f "$pidfile" ]] || return 1
  local pid
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" 2>/dev/null
}

start_backend() {
  is_running "$pid_backend" && return 0
  (cd "$root/packages/opencode" && bun run --conditions=browser ./src/index.ts serve --port 4096) &
  echo $! >"$pid_backend"
  started_pids+=("$!")
}

start_web() {
  is_running "$pid_web" && return 0
  (cd "$root/packages/app" && bun dev -- --port 3000) &
  echo $! >"$pid_web"
  started_pids+=("$!")
}

stop_by_pid() {
  local pidfile="$1"
  [[ -f "$pidfile" ]] || return 0
  local pid
  pid="$(cat "$pidfile" 2>/dev/null || true)"
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
  fi
  rm -f "$pidfile"
}

print_all() {
  echo "Backend: http://localhost:4096"
  echo "App: http://localhost:3000"
}

print_web() { echo "App: http://localhost:3000"; }
print_backend() { echo "Backend: http://localhost:4096"; }

started_pids=()

action="$(printf '%s' "${action}" | tr '[:upper:]' '[:lower:]')"

case "$action" in
  start)
    start_backend
    start_web
    print_all
    ;;
  restart)
    stop_by_pid "$pid_backend"
    stop_by_pid "$pid_web"
    start_backend
    start_web
    print_all
    ;;
  stop)
    stop_by_pid "$pid_backend"
    stop_by_pid "$pid_web"
    exit 0
    ;;
  web)
    stop_by_pid "$pid_web"
    start_web
    print_web
    ;;
  backend)
    stop_by_pid "$pid_backend"
    start_backend
    print_backend
    ;;
  *)
    echo "Usage: dev.sh [start|stop|restart|web|backend]"
    exit 1
    ;;
esac

if [[ ${#started_pids[@]} -gt 0 ]]; then
  wait "${started_pids[@]}"
fi
