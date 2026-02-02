#!/bin/bash

set -e

LOG_FILE="/opt/opencode/logs/auto-update.log"
PROJECT_DIR="/opt/opencode"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "错误：$1"
    exit 1
}

check_commands() {
    for cmd in git bun supervisorctl; do
        if ! command -v "$cmd" &> /dev/null; then
            error_exit "命令 '$cmd' 未找到，请先安装。"
        fi
    done
}

check_git_updates() {
    cd "$PROJECT_DIR" || error_exit "无法切换到项目目录"
    
    log "从远程仓库获取最新更改..."
    git fetch origin || error_exit "获取远程更新失败"
    
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/self)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        log "没有发现新更新。"
        return 1
    else
        log "检测到新更新。"
        return 0
    fi
}

perform_update() {
    cd "$PROJECT_DIR" || error_exit "无法切换到项目目录"
    
    log "开始更新流程..."
    
    log "拉取最新更改..."
    git pull origin self || error_exit "拉取最新更改失败"
    
    log "更新依赖..."
    bun install || error_exit "更新依赖失败"
    
    log "构建 packages/app..."
    cd "$PROJECT_DIR/packages/app" || error_exit "无法切换到 app 目录"
    bun run build || error_exit "构建 packages/app 失败"
    
    log "重启 opencode 服务..."
    supervisorctl restart opencode:opencode_00 || error_exit "重启 opencode 服务失败"
    
    log "更新成功完成！"
}

main() {
    log "=== 开始自动更新检查 ==="
    
    check_commands
    
    if check_git_updates; then
        perform_update
    else
        log "无需操作。"
    fi
    
    log "=== 自动更新检查完成 ==="
    echo "" >> "$LOG_FILE"
}

main "$@"