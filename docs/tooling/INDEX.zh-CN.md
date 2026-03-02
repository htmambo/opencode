# OpenCode 工具体系索引（LSP / MCP / Skills / 扩展）

更新时间：2026-03-02  
适用仓库：`/media/hoping/个人数据/usr/htdocs/opencode`

## 1. 这份索引怎么用

如果你只想快速落地，按这个顺序读：

1. [阅读路径（新手/团队治理/企业接入）](./READING_PATHS.zh-CN.md)
2. [LSP 使用指南](./LSP.zh-CN.md)
3. [MCP 使用指南](./MCP.zh-CN.md)
4. [Skills 使用指南](./SKILLS.zh-CN.md)
5. [权限与安全策略](./PERMISSIONS.zh-CN.md)
6. [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)
7. [配置模板库（opencode + tui，newbie/team/enterprise）](./templates/README.zh-CN.md)

---

## 2. 按功能点找文档

| 功能/目标 | 先看这份 | 你将得到什么 |
| --- | --- | --- |
| 让 AI 有“代码智能”（定义/引用/诊断） | [LSP](./LSP.zh-CN.md) | LSP 启用、配置、排障、与 `lsp` 工具的区别 |
| 让 AI 连接外部系统（GitHub/Jira/Sentry/文档搜索等） | [MCP](./MCP.zh-CN.md) | 本地/远程 MCP、OAuth、按 Agent 开关 |
| 复用团队知识与固定流程模板 | [Skills](./SKILLS.zh-CN.md) | `SKILL.md` 编写规范、权限、加载机制 |
| 控制工具可执行范围（allow/ask/deny） | [Permissions](./PERMISSIONS.zh-CN.md) | 安全基线、通配规则、外部目录控制 |
| 自定义工具能力或全局行为钩子 | [Custom Tools + Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md) | tool 开发、plugin 事件、依赖与加载顺序 |
| 快速套用标准配置 | [模板库](./templates/README.zh-CN.md) | 三套可直接复制的 `opencode.jsonc` + `tui.jsonc` 组合 |

---

## 2.1 按角色快速进入

1. 新人开发：先看 [阅读路径](./READING_PATHS.zh-CN.md) 的“路径 A”。
2. 团队负责人：先看 [阅读路径](./READING_PATHS.zh-CN.md) 的“路径 B”。
3. 企业平台/安全：先看 [阅读路径](./READING_PATHS.zh-CN.md) 的“路径 C”。

---

## 3. 按场景找文档

## 3.1 我要让 AI “更懂项目代码”

1. 先配置 [LSP](./LSP.zh-CN.md)。
2. 再补充 [Skills](./SKILLS.zh-CN.md)（把团队规范固化）。
3. 用 [Permissions](./PERMISSIONS.zh-CN.md) 给 `edit/bash` 加保护。

## 3.2 我要让 AI “连公司系统”

1. 按 [MCP](./MCP.zh-CN.md) 接入远程服务。
2. 用 [Permissions](./PERMISSIONS.zh-CN.md) 控制 MCP 工具访问。
3. 需要深度定制时参考 [Custom Tools + Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)。

## 3.3 我要做“团队级标准化”

1. 用 [Skills](./SKILLS.zh-CN.md) 沉淀可复用技能。
2. 用 [Permissions](./PERMISSIONS.zh-CN.md) 设安全默认值。
3. 用 [Custom Tools + Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md) 实现流程自动化。

---

## 4. 能力边界速记（避免选错）

| 机制 | 适用问题 | 典型产物 |
| --- | --- | --- |
| `AGENTS.md` / `instructions` | 项目级/团队级规则 | 项目行为规范 |
| Skills | 可复用“操作套路”与知识片段 | `skills/*/SKILL.md` |
| Commands | 高频提示词模板 | `.opencode/commands/*.md` |
| Custom Tools | 新增“可调用工具能力” | `.opencode/tools/*.ts` |
| Plugins | 监听事件并改写行为 | `.opencode/plugins/*.ts` |
| MCP | 接入外部工具生态 | `opencode.json` 里的 `mcp` 配置 |
| LSP | 代码语义理解和诊断 | `opencode.json` 里的 `lsp` 配置 |

---

## 5. 对应官方文档入口（仓库内）

以下是工具体系最相关的官方 MDX 源文件：

1. `packages/web/src/content/docs/lsp.mdx`
2. `packages/web/src/content/docs/mcp-servers.mdx`
3. `packages/web/src/content/docs/skills.mdx`
4. `packages/web/src/content/docs/tools.mdx`
5. `packages/web/src/content/docs/custom-tools.mdx`
6. `packages/web/src/content/docs/plugins.mdx`
7. `packages/web/src/content/docs/permissions.mdx`

---

## 6. 本地实践建议

1. 开发完成后优先执行：`./script/dev-fast.sh check`。
2. 修改工具权限后，先用一个最小测试会话验证。
3. MCP/Plugin/Custom Tool 变更建议单独开分支，并保留回滚点。
