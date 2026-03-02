# MCP 使用指南（安装、认证、调用、权限）

更新时间：2026-03-02

## 1. MCP 是什么

MCP（Model Context Protocol）可以把外部工具接入 OpenCode，让模型调用你定义或第三方提供的能力。

常见用途：

1. 接企业内部系统（工单、知识库、发布系统）。
2. 接外部服务（Sentry、Context7、代码搜索等）。
3. 提供比内置工具更专用的操作能力。

---

## 2. 配置结构总览

在 `opencode.json` 中通过 `mcp` 配置：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {}
}
```

每个 MCP 服务是一个命名节点，推荐命名简洁且语义清晰（例如 `context7`、`jira`、`sentry`）。

---

## 3. 本地 MCP（Local）安装与使用

## 3.1 基础配置

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "my-local-mcp": {
      "type": "local",
      "command": ["npx", "-y", "my-mcp-command"],
      "enabled": true,
      "environment": {
        "MY_ENV_VAR": "value"
      }
    }
  }
}
```

## 3.2 字段说明

1. `type`: 必须是 `"local"`。
2. `command`: 启动命令数组。
3. `environment`: 启动时注入环境变量。
4. `enabled`: 是否启用。
5. `timeout`: 获取工具超时（毫秒，默认 5000）。

---

## 4. 远程 MCP（Remote）安装与使用

## 4.1 基础配置

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "my-remote-mcp": {
      "type": "remote",
      "url": "https://example.com/mcp",
      "enabled": true,
      "headers": {
        "Authorization": "Bearer {env:MY_TOKEN}"
      }
    }
  }
}
```

## 4.2 字段说明

1. `type`: 必须是 `"remote"`。
2. `url`: MCP 服务地址。
3. `headers`: 请求头（可放 API key）。
4. `oauth`: OAuth 配置对象或 `false`。
5. `timeout`: 获取工具超时（毫秒）。

---

## 5. OAuth 认证流程（远程 MCP）

## 5.1 自动模式

很多服务可自动触发 OAuth 流程。首次调用时按提示授权即可。

## 5.2 手动命令

```bash
# 对指定 MCP 发起认证
opencode mcp auth my-oauth-server

# 查看认证状态
opencode mcp auth list

# 退出认证
opencode mcp logout my-oauth-server

# 诊断 OAuth 与连接
opencode mcp debug my-oauth-server
```

令牌会存储在 `~/.local/share/opencode/mcp-auth.json`。

## 5.3 预注册客户端

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "my-oauth-server": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "oauth": {
        "clientId": "{env:MCP_CLIENT_ID}",
        "clientSecret": "{env:MCP_CLIENT_SECRET}",
        "scope": "tools:read tools:execute"
      }
    }
  }
}
```

## 5.4 禁用 OAuth 自动探测

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "my-api-mcp": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "oauth": false
    }
  }
}
```

---

## 6. MCP 在会话里的调用方式

MCP 工具注册后，通常用“提示约束”触发模型优先调用：

```text
请使用 context7 工具检索官方文档后给出答案。
```

也可以在 `AGENTS.md`/Skill 中写约定，例如：

```md
需要查文档时优先使用 `context7`。
```

---

## 7. 权限与隔离（重点）

## 7.1 全局开关

可通过 `tools` 配置对 MCP 工具整体开关：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "tools": {
    "my-mcp*": false
  }
}
```

## 7.2 按 Agent 开关

```json
{
  "$schema": "https://opencode.ai/config.json",
  "tools": {
    "my-mcp*": false
  },
  "agent": {
    "my-agent": {
      "tools": {
        "my-mcp*": true
      }
    }
  }
}
```

## 7.3 结合 permission 控制风险

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "my-mcp_*": "ask"
  }
}
```

---

## 8. 常用管理命令

```bash
# 交互式添加
opencode mcp add

# 查看配置与状态
opencode mcp list

# 简写
opencode mcp ls
```

---

## 9. 推荐实践

1. 从少量 MCP 开始，按需增量接入，避免上下文过载。
2. 对高风险 MCP 默认 `ask`，确认稳定后再局部 `allow`。
3. 远程 MCP 尽量使用最小权限 token。
4. 若需团队统一，写入项目级 `opencode.json` 并纳入代码评审。

---

## 10. 排障清单

## 10.1 服务不显示或不生效

1. `opencode mcp list` 看状态。
2. 检查 `enabled` 是否为 `false`。
3. 检查 `tools` 是否全局被禁用。

## 10.2 OAuth 反复失败

1. `opencode mcp debug <name>`。
2. 确认回调、scope、client 信息。
3. 先 `opencode mcp logout <name>` 再重试。

## 10.3 连接超时

1. 检查网络与代理设置。
2. 提高 `timeout`。
3. 对本地 MCP 先直接在终端手动跑 `command` 验证。

---

## 11. 关联文档

1. [工具索引](./INDEX.zh-CN.md)
2. [LSP 指南](./LSP.zh-CN.md)
3. [Skills 指南](./SKILLS.zh-CN.md)
4. [权限策略](./PERMISSIONS.zh-CN.md)

