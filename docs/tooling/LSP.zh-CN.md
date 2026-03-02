# LSP 使用指南（安装、配置、验证、排障）

更新时间：2026-03-02

## 1. LSP 在 OpenCode 里解决什么问题

LSP（Language Server Protocol）主要提供：

1. 语义级代码理解（定义、引用、符号、悬停信息）。
2. 诊断信息（错误、警告）反馈给模型与界面。
3. 更精确的代码修改上下文。

一句话：LSP 让 AI 不只“看文本”，而是“读语义”。

---

## 2. 启用前提（安装相关）

## 2.1 内置 LSP 机制

OpenCode 内置了大量语言的 LSP 适配，检测到扩展名并满足依赖后会自动启用。

常见示例：

1. TypeScript：项目里有 `typescript` 依赖。
2. Go：系统有 `go`。
3. Rust：系统有 `rust-analyzer`。
4. Java：系统有 Java SDK（文档要求 21+）。
5. PHP：会为 Intelephense 场景自动处理（按官方文档）。

## 2.2 依赖验证（建议）

先确认对应语言工具链可用，例如：

```bash
go version
rust-analyzer --version
java -version
```

## 2.3 自动下载控制

如果你不希望 OpenCode 自动下载 LSP 组件，可设置：

```bash
export OPENCODE_DISABLE_LSP_DOWNLOAD=true
```

---

## 3. 基础配置

在项目根 `opencode.json` 中配置 `lsp`：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {}
}
```

## 3.1 全局禁用 LSP

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": false
}
```

## 3.2 禁用单个 LSP

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "typescript": {
      "disabled": true
    }
  }
}
```

## 3.3 自定义命令/扩展名

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "custom-lsp": {
      "command": ["custom-lsp-server", "--stdio"],
      "extensions": [".custom"]
    }
  }
}
```

## 3.4 环境变量与初始化参数

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "rust": {
      "env": {
        "RUST_LOG": "debug"
      }
    },
    "typescript": {
      "initialization": {
        "preferences": {
          "importModuleSpecifierPreference": "relative"
        }
      }
    }
  }
}
```

---

## 4. 使用方式

## 4.1 在 TUI/CLI 中的日常使用

LSP 不需要你手动“调用命令”才生效。它会在文件访问和编辑流程中自动参与，向模型提供诊断和语义信息。

## 4.2 通过 Server API 验证 LSP 状态

```bash
opencode serve --port 4096
curl -s http://127.0.0.1:4096/lsp
```

如果你装了 `jq`，可加上格式化：

```bash
curl -s http://127.0.0.1:4096/lsp | jq
```

---

## 5. `lsp` 工具与 LSP Server 的区别

这是常见误区：

1. `lsp server`：后台语言服务，负责诊断与语义能力。
2. `lsp tool`：给模型显式调用的工具接口（实验特性）。

要让模型显式调用 `lsp` 工具，需要额外打开实验开关：

```bash
export OPENCODE_EXPERIMENTAL_LSP_TOOL=true
```

并在权限中允许：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "lsp": "allow"
  }
}
```

---

## 6. 推荐实践

1. 对大型仓库，先只开核心语言 LSP，减少启动开销。
2. 团队统一 `opencode.json` 中的 `lsp` 配置，避免环境漂移。
3. 与 `Skills` 联用：在 Skill 中约定“遇到类型/引用问题优先使用 LSP 信息”。
4. 与 `Permissions` 联用：将高风险写操作设为 `ask`，LSP 保持 `allow`。

---

## 7. 故障排查

## 7.1 看不到诊断

1. 检查文件扩展名是否被对应 LSP 覆盖。
2. 检查语言依赖是否安装。
3. 检查是否在 `opencode.json` 中被 `disabled`。

## 7.2 启动慢或异常

1. 查看日志目录：`~/.local/share/opencode/log/`。
2. 临时禁用对应 LSP，逐个恢复定位问题。
3. 如有自动下载问题，明确设置 `OPENCODE_DISABLE_LSP_DOWNLOAD` 并手工安装依赖。

## 7.3 只想要“文本模式”

直接把 `lsp` 设为 `false`，确认行为是否恢复。

---

## 8. 关联文档

1. [工具索引](./INDEX.zh-CN.md)
2. [MCP 指南](./MCP.zh-CN.md)
3. [Skills 指南](./SKILLS.zh-CN.md)
4. [权限策略](./PERMISSIONS.zh-CN.md)

