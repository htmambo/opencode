# Custom Tools 与 Plugins 指南（扩展能力）

更新时间：2026-03-02

## 1. 先选型：Tool 还是 Plugin？

## 1.1 选择规则

| 需求 | 优先方案 |
| --- | --- |
| 给模型新增一个可调用动作（如 `query_db`） | Custom Tool |
| 在执行前后拦截/改写行为（如拦截读 `.env`） | Plugin |
| 接外部已有工具生态 | MCP |
| 固化提示流程，不增加执行能力 | Skill |

## 1.2 常见误区

1. 想“控制行为”却写成 Skill：Skill 只是说明，不是执行拦截。
2. 想“新增动作”却写成 Plugin：动作定义更适合 Tool。
3. 想“接外部服务”却手写 Plugin：优先看是否已有 MCP。

---

## 2. Custom Tools（安装与使用）

## 2.1 放置路径

1. 项目级：`.opencode/tools/`
2. 全局：`~/.config/opencode/tools/`

## 2.2 最小 Tool 示例

```ts
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "查询项目数据库",
  args: {
    query: tool.schema.string().describe("SQL query"),
  },
  async execute(args) {
    return `Executed: ${args.query}`
  },
})
```

文件名即工具名。例如 `database.ts` -> `database`。

## 2.3 单文件多工具

如果同一文件导出多个工具，命名规则为 `<filename>_<exportname>`。

例如 `math.ts` 导出 `add` 和 `multiply`，工具名是：

1. `math_add`
2. `math_multiply`

## 2.4 参数与上下文

1. 参数用 `tool.schema`（Zod）定义。
2. `execute(args, context)` 可拿到 `agent/sessionID/messageID/directory/worktree`。

## 2.5 调用其他语言脚本

Tool 定义推荐用 TS/JS，但执行逻辑可调用 Python/Go/Shell 等脚本。

---

## 3. Tool 冲突与权限

## 3.1 命名冲突

如果自定义 Tool 与内置 Tool 同名，自定义 Tool 优先。  
除非你明确要覆盖，否则建议使用唯一前缀（如 `team_`）。

## 3.2 与 permission 联动

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "team_*": "ask"
  }
}
```

---

## 4. Plugins（安装与使用）

## 4.1 加载方式

1. 本地插件目录：
   - 项目级：`.opencode/plugins/`
   - 全局：`~/.config/opencode/plugins/`
2. npm 插件：在 `opencode.json` 的 `plugin` 数组声明。

## 4.2 npm 插件示例

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["opencode-helicone-session", "@my-org/custom-plugin"]
}
```

## 4.3 本地插件最小示例

```ts
export const MyPlugin = async ({ $, client, directory, worktree }) => {
  return {
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash") {
        // 在这里做审计/改写/阻断
      }
    },
  }
}
```

---

## 5. Plugin 事件与典型用法

常见事件域：

1. `tool.execute.before/after`：工具调用前后拦截。
2. `shell.env`：注入环境变量。
3. `session.*`：会话生命周期。
4. `tui.*`：UI 交互事件。
5. `permission.*`：权限询问与响应链路。

适用示例：

1. 审计高风险命令。
2. 自动注入企业环境变量。
3. 会话完成后发系统通知。

---

## 6. 本地依赖安装

如果本地 Tool/Plugin 需要第三方包，创建 `.opencode/package.json`：

```json
{
  "dependencies": {
    "shescape": "^2.1.0"
  }
}
```

OpenCode 会在启动时执行依赖安装（Bun 生态）。

---

## 7. 插件加载顺序（重要）

按顺序加载：

1. 全局 config（`~/.config/opencode/opencode.json`）
2. 项目 config（`opencode.json`）
3. 全局插件目录
4. 项目插件目录

后加载的逻辑可能覆盖先加载行为，排查冲突时按这个顺序定位。

---

## 8. 推荐工程实践

1. Tool 命名统一前缀（如 `org_`）。
2. Plugin 一次只改一个行为面，避免巨型插件。
3. 高风险逻辑先走 `ask`，再灰度到 `allow`。
4. 每个 Tool/Plugin 必写最小 usage 示例，便于团队复用。
5. 重大行为变更记录到 `AGENTS.md` 或项目文档。

---

## 9. 排障清单

## 9.1 Tool 不出现

1. 目录是否正确（`.opencode/tools`）。
2. 导出是否默认/命名正确。
3. 是否被 permission 拦截。

## 9.2 Plugin 不生效

1. 检查插件加载位置与顺序。
2. 检查依赖是否安装成功。
3. 通过日志确认事件是否触发。

## 9.3 行为冲突

1. 暂时禁用全部插件，逐个恢复。
2. 对冲突工具加唯一前缀，避免覆盖内置工具。

---

## 10. 关联文档

1. [工具索引](./INDEX.zh-CN.md)
2. [MCP 指南](./MCP.zh-CN.md)
3. [Skills 指南](./SKILLS.zh-CN.md)
4. [权限策略](./PERMISSIONS.zh-CN.md)

