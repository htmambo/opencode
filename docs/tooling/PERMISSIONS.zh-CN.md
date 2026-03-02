# Permissions 指南（工具安全与审批策略）

更新时间：2026-03-02

## 1. 权限模型

OpenCode 的每条权限规则最终会落到三种动作之一：

1. `allow`：直接执行。
2. `ask`：执行前询问。
3. `deny`：禁止执行。

这是你控制 LSP/MCP/Skills/Tool 风险边界的核心机制。

---

## 2. 基础配置

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "*": "ask",
    "read": "allow",
    "edit": "ask",
    "bash": "ask"
  }
}
```

---

## 3. 常用权限键

## 3.1 高频项

1. `read`
2. `edit`（覆盖 `edit/write/patch/multiedit`）
3. `bash`
4. `lsp`
5. `skill`
6. `webfetch` / `websearch`
7. `task`
8. `todoread` / `todowrite`
9. `external_directory`
10. `doom_loop`

## 3.2 默认值要点

1. 大部分权限默认 `allow`。
2. `external_directory` 和 `doom_loop` 默认 `ask`。
3. `read` 默认允许，但对 `.env` 默认拒绝（`.env.example` 例外）。

---

## 4. 细粒度规则（对象语法）

权限支持模式匹配，且“最后匹配生效”。

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "bash": {
      "*": "ask",
      "git *": "allow",
      "npm *": "allow",
      "rm *": "deny"
    },
    "edit": {
      "*": "deny",
      "packages/web/src/content/docs/*.mdx": "allow"
    }
  }
}
```

---

## 5. LSP / MCP / Skills 组合建议

## 5.1 稳健默认（推荐）

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "read": "allow",
    "lsp": "allow",
    "skill": "allow",
    "bash": "ask",
    "edit": "ask",
    "external_directory": "ask",
    "doom_loop": "ask"
  }
}
```

## 5.2 MCP 强约束

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "mymcp_*": "ask"
  }
}
```

---

## 6. 按 Agent 覆盖权限

可以给不同 Agent 配不同安全级别：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "deny",
    "bash": "ask"
  },
  "agent": {
    "build": {
      "permission": {
        "edit": "ask"
      }
    },
    "plan": {
      "permission": {
        "edit": "deny",
        "bash": "deny"
      }
    }
  }
}
```

---

## 7. 外部目录控制（防越界）

如果需要允许访问项目外目录，显式配置 `external_directory`：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "external_directory": {
      "~/projects/personal/**": "allow"
    },
    "edit": {
      "~/projects/personal/**": "deny"
    }
  }
}
```

---

## 8. 通配符规则速记

1. `*`：匹配任意长度。
2. `?`：匹配单字符。
3. 其余字符按字面匹配。

例子：

1. `git *`：允许 `git status`、`git diff` 等。
2. `mcp_*`：匹配某类 MCP 工具前缀。

---

## 9. 三套可直接用的策略模板

## 9.1 开发日常（建议）

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "read": "allow",
    "lsp": "allow",
    "skill": "allow",
    "edit": "ask",
    "bash": {
      "*": "ask",
      "git *": "allow"
    }
  }
}
```

## 9.2 审计模式（只读）

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "read": "allow",
    "lsp": "allow",
    "skill": "allow",
    "edit": "deny",
    "bash": "deny"
  }
}
```

## 9.3 自动化流水线（受控执行）

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "read": "allow",
    "edit": "ask",
    "bash": {
      "*": "deny",
      "bun typecheck": "allow",
      "git status *": "allow"
    }
  }
}
```

---

## 10. 排障清单

## 10.1 为什么总是弹确认

1. 看是否命中 `* -> ask`。
2. 看更具体规则是否写在前面却被后续覆盖。
3. 检查是否为 `external_directory` 触发。

## 10.2 为什么工具“消失了”

1. 对应权限可能是 `deny`。
2. 对应 Agent 里可能覆写为禁用。
3. MCP/Skill 可能被全局工具开关禁用。

## 10.3 为什么行为与预期不一致

1. 规则是“最后匹配生效”。
2. 检查项目级与全局配置叠加后的最终结果。

---

## 11. 关联文档

1. [工具索引](./INDEX.zh-CN.md)
2. [LSP 指南](./LSP.zh-CN.md)
3. [MCP 指南](./MCP.zh-CN.md)
4. [Skills 指南](./SKILLS.zh-CN.md)
5. [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)

