# `opencode.json` + `tui.json` 模板库（新手 / 团队 / 企业）

更新时间：2026-03-02

## 1. 使用方式

### 1.1 推荐：同档位成套复制

在仓库根目录执行（任选一档）：

```bash
# 新手档
cp docs/tooling/templates/opencode.newbie.jsonc opencode.jsonc
cp docs/tooling/templates/tui.newbie.jsonc tui.jsonc

# 团队档
cp docs/tooling/templates/opencode.team.jsonc opencode.jsonc
cp docs/tooling/templates/tui.team.jsonc tui.jsonc

# 企业档
cp docs/tooling/templates/opencode.enterprise.jsonc opencode.jsonc
cp docs/tooling/templates/tui.enterprise.jsonc tui.jsonc
```

### 1.2 仅替换 TUI 体验配置

```bash
cp docs/tooling/templates/tui.team.jsonc tui.jsonc
```

然后按你的实际情况修改：

1. `opencode.jsonc`：`model` / `small_model`、`mcp`、`permission`。
2. `tui.jsonc`：`theme`、`keybinds`、`scroll_acceleration`、`diff_style`。

## 2. 两类配置分别管什么

| 文件 | 负责范围 | 典型字段 |
| --- | --- | --- |
| `opencode.json(c)` | 模型、权限、MCP、Agent、Plugin、Server | `model`、`permission`、`mcp`、`agent` |
| `tui.json(c)` | 终端界面体验与快捷键 | `theme`、`keybinds`、`scroll_speed`、`diff_style` |

## 3. 模板选择建议

| 档位 | 推荐场景 | 组合 |
| --- | --- | --- |
| Newbie | 个人开发、快速上手 | `opencode.newbie` + `tui.newbie` |
| Team | 小团队协作、流程标准化 | `opencode.team` + `tui.team` |
| Enterprise | 企业接入、安全审计优先 | `opencode.enterprise` + `tui.enterprise` |

## 4. 落地后建议调整项

1. 模型与 Provider：`model`、`small_model`、`baseURL`、超时等。
2. MCP：服务 URL、认证信息、`enabled` 开关。
3. 权限：`permission` 的 `allow/ask/deny` 与命令通配规则。
4. TUI 键位：`keybinds.leader`、是否禁用 `session_share`、`username_toggle`。
5. 交互体验：`scroll_acceleration.enabled` 与 `diff_style`。

## 5. 配套文档

1. [工具索引](../INDEX.zh-CN.md)
2. [阅读路径](../READING_PATHS.zh-CN.md)
3. [LSP 使用指南](../LSP.zh-CN.md)
4. [MCP 使用指南](../MCP.zh-CN.md)
5. [Skills 使用指南](../SKILLS.zh-CN.md)
6. [权限策略](../PERMISSIONS.zh-CN.md)
