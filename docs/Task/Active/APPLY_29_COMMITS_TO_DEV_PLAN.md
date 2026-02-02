# 将 29 个提交移植到 dev 分支

**Status**: 🔄 In progress (start time: 2026-08-02)
**Creator**: opencode
**Branch**: `apply-features`（基于 dev）

## 任务目标

将 `merge/upstream-dev-20260209` 分支领先 `dev` 的 29 个提交（22 个非 merge 功能提交）应用到 `dev` 分支的最新状态上（dev 已领先 5464 个提交）。

## 背景

- 分叉点：`bf2cc3aa2`
- dev 已前进 5464 个提交，包含大量新功能
- 需移植的功能组：
  1. 布局面板与会话页增强
  2. 设置页可视化 + JSON 配置编辑器
  3. prompt dock 与性能工具
  4. 打包/开发脚本
  5. zh-CN 文档与配置模板

## 实施方案

1. 从 `dev` 新建分支 `apply-features`
2. 按提交顺序 cherry-pick 22 个非 merge 提交（跳过 7 个 merge commit）
3. 冲突处理原则：**以 dev 新版代码为准**，纯新增文件直接合入，高频改动文件手动移植关键逻辑
4. 验证：类型检查 + 构建

## 高风险文件（dev 侧频繁改动）

| 文件 | dev 侧改动次数 |
|---|---|
| `packages/app/src/pages/layout.tsx` | 100 |
| `packages/app/src/i18n/en.ts` | 68 |
| `packages/app/src/pages/session/message-timeline.tsx` | 52 |
| `packages/app/src/components/settings-general.tsx` | 38 |
| `packages/app/src/context/settings.tsx` | 37 |
| `packages/app/src/pages/layout/sidebar-items.tsx` | 29 |
| `packages/app/src/components/session/session-header.tsx` | 28 |

## 子任务状态

- [x] 创建任务文档
- [ ] 从 dev 新建 apply-features 分支
- [ ] cherry-pick 22 个非 merge 功能提交
- [ ] 解决冲突
- [ ] 验证：类型检查 + 构建
- [ ] 更新文档并归档

## 验收标准

- `apply-features` 分支包含全部 22 个功能提交的代码变更
- `packages/app` 类型检查通过
- 构建通过
