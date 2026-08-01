# 将 29 个提交移植到 dev 分支

**Status**: ✅ Completed (completion time: 2026-08-02)
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

## 执行结果

### 移植成功的功能

| 功能 | 说明 |
|---|---|
| `settings-config.tsx`（+680 行） | 可视化 + JSON 配置编辑器，接入 dialog-settings 的 config tab（含 i18n keys ×32） |
| `sidebar-items.tsx` 导出按钮 | SessionItem 增加 exportSession 按钮（dev 缺失的独有功能） |
| `layout.tsx` exportSession | 移植函数（改用 dev 的 serverSDK 模式），接入 ctx 链 |
| 脚本（dev.sh/dev.cmd/dev.ps1/dev-fast.sh/auto-update.sh 等） | 纯新增，无冲突 |
| zh-CN 文档 + 配置模板 | 纯新增，无冲突 |
| `perf.ts`、`question-dock.tsx` | 纯新增 |
| i18n keys（en/zh 各 +33） | 合并双方独有 key |
| 桌面打包脚本（build-linux.sh/build-mac.sh） | 纯新增 |

### 放弃移植（dev 已有等价实现）

| 旧功能 | dev 中的等价实现 |
|---|---|
| session-header 的 share/terminal 按钮 | dev 版 SessionHeaderV2Actions |
| 布局面板增强（layout.tsx 重构） | dev 全新布局（newSessionDesign 双布局 + SessionSidePanel） |
| message-timeline.tsx（旧路径） | dev 已迁移至 `timeline/` 子目录 |
| session-prompt-dock.tsx | dev 重构为 `composer/session-question-dock.tsx` |
| session-turn.css | dev 迁移至 `packages/session-ui` |
| "对齐 dev 类型"提交（ae63f44d9 等） | 已用 dev 版本，无需对齐 |

### 冲突处理统计

- 共 22 个非 merge 提交，约 40+ 处冲突
- 3 个小提交（focusedFile、2 个 i18n key）内容已被 dev 包含，跳过
- 2 个中间提交存在残留冲突标记被误提交，用 `git checkout dev --` 重置后重新移植

## 验收结果

- ✅ `apply-features` 分支包含全部功能提交的代码变更（36 文件，+4193/-5）
- ✅ `packages/app` typecheck 通过（tsgo -b）
- ✅ `packages/app` build 通过（36.6s）
- ✅ `packages/ui` typecheck 通过

## 提交记录（dev..HEAD）

```
259e295e3 feat(app): port layout enhancements and config editor onto dev
f21b2d532 fix(app): clean up leftover merge conflict markers
487e838dd docs: add comprehensive zh-CN project and tooling guides
453141b51 build script
dc9dcc3c8 max width
46c675654 something
aad7555cd Ignore tsbuildinfo
9948b3e49 Add config i18n keys
1c5b982b5 Sync en i18n with dev
bd3be0ef3 Add settings fields and i18n keys
e8bc87f49 Align app types with dev
e8ec4bbea Add open-file icon
179a668dd Fix missing session imports
05384fe2d something
7a2836451 feat(app): add visual and json config editor in settings
f92654a18 something
2a16a3586 fix(app): restore session import/export buttons
7612dd2a8 fix(app): restore missing open-in-app definitions after merge
88500d0ba 优化打包脚本
0719b06aa 一键脚本
1b6d1d0a8 feat(app): 增强布局面板和会话页面功能
```

## 经验总结

1. **cherry-pick 冲突解决时不要 `git add -A`**——会把未解决的冲突文件（带标记）一起提交
2. **dev 已删除的文件（DU 状态）**应先确认 dev 是否有迁移路径，再决定 git rm
3. **"对齐类型"类提交（如 ae63f44d9）在移植到新版 dev 后通常不再需要**，直接以 dev 为准
4. **冲突标记残留检查**：提交前必须 `rg '^<<<<<<<'` 全库扫描
