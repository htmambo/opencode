# 工具文档阅读路径（新手 / 团队治理 / 企业接入）

更新时间：2026-03-02

## 1. 如何使用这份路径文档

如果你面对的是“我该先读哪篇”的问题，不要先看所有文档。  
按你的目标选择一个路径，按顺序阅读并执行对应检查项。

---

## 2. 路径 A：新手快速上手（1-2 天）

适用人群：第一次接触本项目，需要尽快稳定使用 LSP/MCP/Skills。

## 2.1 阅读顺序

1. [LSP 使用指南](./LSP.zh-CN.md)
2. [MCP 使用指南](./MCP.zh-CN.md)
3. [Skills 使用指南](./SKILLS.zh-CN.md)
4. [权限策略](./PERMISSIONS.zh-CN.md)
5. [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)
6. [模板库（newbie：opencode + tui）](./templates/README.zh-CN.md)

## 2.2 执行检查项

1. 能看到 LSP 状态并确认目标语言已启用。
2. 至少接入 1 个 MCP（本地或远程）。
3. 创建 1 个可被发现的 Skill（含合法 frontmatter）。
4. 把 `edit`、`bash` 设为 `ask` 并验证审批行为。
5. 运行一次 `./script/dev-fast.sh check` 确认流程可用。

## 2.3 产出标准

1. 项目中已有可运行的 `opencode.json` + `tui.json` 成套配置。
2. 你能解释 Tool/MCP/Skill/Plugin 的边界。
3. 你能完成一次“配置 -> 验证 -> 推送”的闭环。

---

## 3. 路径 B：团队治理与规范化（2-5 天）

适用人群：Tech Lead、Maintainer、平台工程同学，需要团队级一致性。

## 3.1 阅读顺序

1. [权限策略](./PERMISSIONS.zh-CN.md)
2. [Skills 使用指南](./SKILLS.zh-CN.md)
3. [MCP 使用指南](./MCP.zh-CN.md)
4. [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)
5. [LSP 使用指南](./LSP.zh-CN.md)
6. [模板库（team：opencode + tui）](./templates/README.zh-CN.md)

## 3.2 执行检查项

1. 制定团队默认权限基线（`allow/ask/deny`）。
2. 定义 Skills 命名规范与目录结构。
3. 梳理“允许接入的 MCP 白名单”。
4. 把高风险行为（`edit/bash/external_directory`）纳入审批。
5. 为关键扩展（Tool/Plugin）建立最小验证流程。

## 3.3 产出标准

1. 可审计的团队配置模板（建议项目内版本化）。
2. 至少 1 份团队 Skill 库（可复用）。
3. 文档化的 MCP 接入与下线流程。

---

## 4. 路径 C：企业接入与安全优先（3-10 天）

适用人群：企业平台团队、合规与安全负责人。

## 4.1 阅读顺序

1. [MCP 使用指南](./MCP.zh-CN.md)
2. [权限策略](./PERMISSIONS.zh-CN.md)
3. [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)
4. [Skills 使用指南](./SKILLS.zh-CN.md)
5. [LSP 使用指南](./LSP.zh-CN.md)
6. [模板库（enterprise：opencode + tui）](./templates/README.zh-CN.md)

## 4.2 执行检查项

1. 远程 MCP 认证与 token 策略明确（最小权限）。
2. 默认 `ask` 或 `deny` 的高风险操作策略落地。
3. 外部目录访问策略（`external_directory`）最小化。
4. 插件加载顺序与审计策略明确。
5. 关键日志与排障路径可被运维团队复现。

## 4.3 产出标准

1. 企业级工具接入清单（含风险级别）。
2. 可执行的权限基线与例外审批流程。
3. 新团队成员可按文档完成接入与自测。

---

## 5. 按问题反查推荐

| 你遇到的问题 | 先读 |
| --- | --- |
| 模型改代码不稳定 | [LSP](./LSP.zh-CN.md) + [Permissions](./PERMISSIONS.zh-CN.md) |
| 想接 Jira / Sentry / 文档搜索 | [MCP](./MCP.zh-CN.md) |
| 想沉淀团队固定套路 | [Skills](./SKILLS.zh-CN.md) |
| 想新增可调用动作 | [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md) |
| 想先把风险收住 | [Permissions](./PERMISSIONS.zh-CN.md) |

---

## 6. 推荐推进顺序（从试点到全量）

1. 单分支试点：先配置 LSP + 1 个 MCP + 基线权限。
2. 小团队灰度：补充 Skills 与最小 Plugin。
3. 全团队推广：固化模板，纳入代码评审与 CI 检查。

---

## 7. 关联文档

1. [工具索引](./INDEX.zh-CN.md)
2. [项目总指南](../PROJECT_USAGE_GUIDE.zh-CN.md)
