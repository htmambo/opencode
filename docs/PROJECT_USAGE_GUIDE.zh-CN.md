# OpenCode 项目使用说明（开发者版，全功能覆盖）

更新时间：2026-03-02  
适用仓库：`/media/hoping/个人数据/usr/htdocs/opencode`

## 1. 文档目标

这份文档面向当前仓库的开发者，目标是：

1. 用最少试错成本跑起项目并进入稳定开发状态。
2. 提供日常高频工作流（同步 `dev`、校验、推送、调试）。
3. 覆盖项目主要功能面（CLI/TUI/Web/Desktop/Server/SDK/Provider/MCP/插件/权限/配置等）。
4. 给出扩展点入口（自定义 Agent、Command、Tool、Plugin、Skill）。

如果你是第一次接触这个仓库，建议从第 3 章按顺序走到第 8 章。

---

## 1.1 工具专题入口

针对 LSP / MCP / Skills / 权限 / 扩展开发的分文档索引：

- [工具索引（tooling）](./tooling/INDEX.zh-CN.md)
- [工具阅读路径（新手/团队治理/企业接入）](./tooling/READING_PATHS.zh-CN.md)
- [`opencode.json` + `tui.json` 模板库（newbie/team/enterprise）](./tooling/templates/README.zh-CN.md)

---

## 2. 仓库结构与模块职责

### 2.1 顶层关键目录

| 路径 | 作用 |
| --- | --- |
| `packages/opencode` | 核心 CLI/TUI + Server 逻辑 |
| `packages/app` | Web UI 应用（共享前端） |
| `packages/ui` | 通用 UI 组件与样式 |
| `packages/desktop` | Tauri 桌面壳（包装 app） |
| `packages/sdk/js` | JavaScript/TypeScript SDK |
| `packages/web` | 官方文档站点内容（MDX） |
| `script/` | 仓库级脚本（生成、发布、开发辅助） |
| `.husky/` | Git hooks（包括 pre-push 检查） |
| `docs/` | 仓库自定义文档（本文件也在此） |

### 2.2 关键事实（本仓库约定）

1. 默认主分支是 `dev`，不是 `main`。
2. 根目录 `test` 脚本被显式禁用（防误跑）。
3. 推送前会触发 `pre-push`，默认跑 `bun typecheck`（全仓 `turbo`）。
4. JS SDK 重新生成入口：`./packages/sdk/js/script/build.ts`。

---

## 3. 环境准备

### 3.1 必备工具

1. `bun`（建议与仓库锁定版本一致：`1.3.10`）。
2. `git`。
3. 可选：`node`、`npm`（某些生态命令或插件会用到）。
4. 如果开发 Desktop：需安装 Tauri 前置（Rust toolchain + 平台依赖）。

### 3.2 初始化步骤

在仓库根目录执行：

```bash
bun --version
bun install
```

建议确认当前分支与工作区状态：

```bash
git branch --show-current
git status -sb
```

---

## 4. 启动方式总览（CLI / TUI / Web / Desktop）

## 4.1 根脚本快捷入口

```bash
# 启动核心开发入口（packages/opencode）
bun dev

# 仅跑 web UI（packages/app）
bun dev:web

# 跑桌面应用（Tauri）
bun dev:desktop
```

## 4.2 CLI/TUI 常见入口

```bash
# 在当前目录打开 TUI
opencode

# 指定项目目录
opencode /path/to/project

# 直接运行单次指令（非交互）
opencode run "Explain this codebase"
```

## 4.3 Headless Server / Web 模式

```bash
# 启动 API server
opencode serve --port 4096

# 启动 web 界面（自动开浏览器）
opencode web --port 4096 --hostname 127.0.0.1

# 第二个终端附着 TUI 到已运行 server
opencode attach http://localhost:4096
```

## 4.4 本仓库附加脚本

`script/dev.sh`（以及 `dev.ps1`/`dev.cmd`/`dev.ts`）用于同时拉起 backend + app。  
本仓库新增 `script/dev-fast.sh` 用于“同步 + 校验 + 推送”流水线：

```bash
# 默认：sync + check + full typecheck
./script/dev-fast.sh

# 仅同步 dev
./script/dev-fast.sh sync

# 仅校验
./script/dev-fast.sh check

# 全流程后直接推送
./script/dev-fast.sh push
```

---

## 5. 配置体系（`opencode.json` / `tui.json` / 环境变量）

## 5.1 配置格式

支持 `JSON` 和 `JSONC`（带注释）。

## 5.2 配置优先级（高到低覆盖关系）

按加载顺序（后者覆盖前者冲突字段）：

1. Remote config（`.well-known/opencode`）
2. Global config（`~/.config/opencode/opencode.json`）
3. `OPENCODE_CONFIG` 指定文件
4. Project config（项目内 `opencode.json`）
5. `.opencode` 目录资源（agents/commands/plugins/skills/tools/themes）
6. `OPENCODE_CONFIG_CONTENT`（运行时 inline 覆盖）

## 5.3 常见配置文件

1. `opencode.json`：模型、Provider、Server、权限、MCP、插件等。
2. `tui.json`：主题、键位、TUI 行为。
3. `AGENTS.md`：项目规则与协作约束（Prompt 级）。

## 5.4 常用环境变量

1. `OPENCODE_CONFIG`：指定配置文件路径。
2. `OPENCODE_CONFIG_DIR`：指定配置目录。
3. `OPENCODE_SERVER_PASSWORD` / `OPENCODE_SERVER_USERNAME`：保护 `serve`/`web`。
4. `OPENCODE_ENABLE_EXA=1`：启用 `websearch`（非 OpenCode provider 场景）。
5. `OPENCODE_DISABLE_LSP_DOWNLOAD=true`：禁用 LSP 自动下载。

## 5.5 配置模板快速起步（推荐）

首次接入建议直接套用仓库内模板库，减少试错：

```bash
# 新手档（推荐从这里开始）
cp docs/tooling/templates/opencode.newbie.jsonc opencode.jsonc
cp docs/tooling/templates/tui.newbie.jsonc tui.jsonc
```

团队或企业场景可替换为对应档位：

1. Team：`opencode.team.jsonc` + `tui.team.jsonc`
2. Enterprise：`opencode.enterprise.jsonc` + `tui.enterprise.jsonc`

详细说明见：[模板库文档](./tooling/templates/README.zh-CN.md)

---

## 6. 全功能覆盖索引（建议收藏）

下面按功能域列出“用途 + 对应官方文档文件（仓库内）”。

| 功能域 | 你能做什么 | 文档路径 |
| --- | --- | --- |
| Intro | 安装、初始化、上手示例 | `packages/web/src/content/docs/index.mdx` |
| CLI | 所有命令与 flags | `packages/web/src/content/docs/cli.mdx` |
| TUI | 会话交互、slash commands、`!` 命令 | `packages/web/src/content/docs/tui.mdx` |
| Web | 浏览器访问模式、端口/主机/CORS | `packages/web/src/content/docs/web.mdx` |
| Server | Headless API、OpenAPI、SSE 事件 | `packages/web/src/content/docs/server.mdx` |
| SDK | JS/TS 客户端、类型安全调用 | `packages/web/src/content/docs/sdk.mdx` |
| Config | 配置格式、优先级、Schema | `packages/web/src/content/docs/config.mdx` |
| Agents | 主/子 Agent、切换、定制 | `packages/web/src/content/docs/agents.mdx` |
| Modes | build/plan 思路与工具限制 | `packages/web/src/content/docs/modes.mdx` |
| Models | 模型选择、默认模型、variants | `packages/web/src/content/docs/models.mdx` |
| Providers | 75+ Provider 接入方式 | `packages/web/src/content/docs/providers.mdx` |
| Permissions | allow/ask/deny 细粒度策略 | `packages/web/src/content/docs/permissions.mdx` |
| Tools | 内置工具能力与权限映射 | `packages/web/src/content/docs/tools.mdx` |
| Custom Tools | 自定义工具定义与参数 | `packages/web/src/content/docs/custom-tools.mdx` |
| MCP Servers | 本地/远程 MCP、OAuth、调试 | `packages/web/src/content/docs/mcp-servers.mdx` |
| Plugins | 插件加载、事件钩子、扩展行为 | `packages/web/src/content/docs/plugins.mdx` |
| Skills | `SKILL.md` 机制与权限 | `packages/web/src/content/docs/skills.mdx` |
| Rules | `AGENTS.md` 与指令来源优先级 | `packages/web/src/content/docs/rules.mdx` |
| Commands | 自定义 `/command` 模板 | `packages/web/src/content/docs/commands.mdx` |
| Keybinds | `tui.json` 键位重映射 | `packages/web/src/content/docs/keybinds.mdx` |
| LSP | 内置语言服务器、扩展配置 | `packages/web/src/content/docs/lsp.mdx` |
| Formatters | 自动格式化器列表与覆盖 | `packages/web/src/content/docs/formatters.mdx` |
| Themes | 主题系统、自定义主题 JSON | `packages/web/src/content/docs/themes.mdx` |
| Share | 会话分享/撤销、隐私注意 | `packages/web/src/content/docs/share.mdx` |
| Network | 代理与证书 | `packages/web/src/content/docs/network.mdx` |
| IDE | IDE 集成入口 | `packages/web/src/content/docs/ide.mdx` |
| ACP | Agent Client Protocol 集成 | `packages/web/src/content/docs/acp.mdx` |
| GitHub | GitHub agent 自动化 | `packages/web/src/content/docs/github.mdx` |
| GitLab | GitLab CI / Duo 集成 | `packages/web/src/content/docs/gitlab.mdx` |
| Enterprise | 企业部署与策略 | `packages/web/src/content/docs/enterprise.mdx` |
| Zen | OpenCode Zen 服务说明 | `packages/web/src/content/docs/zen.mdx` |
| Go | OpenCode Go 计费与目标 | `packages/web/src/content/docs/go.mdx` |
| Ecosystem | 社区插件/项目入口 | `packages/web/src/content/docs/ecosystem.mdx` |
| Troubleshooting | 日志、缓存、故障定位 | `packages/web/src/content/docs/troubleshooting.mdx` |
| Windows + WSL | Windows 推荐实践 | `packages/web/src/content/docs/windows-wsl.mdx` |

---

## 7. 日常开发推荐工作流（当前仓库定制）

## 7.1 拉最新并同步 `dev`（不破坏当前分支）

```bash
# 1) 确保工作区干净
git status --porcelain

# 2) 拉取 dev
git fetch origin dev

# 3) 合并到当前分支（保留你当前分支历史）
git merge --no-ff origin/dev
```

如果你希望一键执行：

```bash
./script/dev-fast.sh sync
```

## 7.2 开发后校验（先快后全）

```bash
# 按改动目录自动触发 app/ui/opencode/sdk 级别检查，再跑全量
./script/dev-fast.sh check
```

等价手动执行（按需）：

```bash
bun run --cwd packages/ui typecheck
bun run --cwd packages/app typecheck
bun run --cwd packages/app test:unit
bun run --cwd packages/opencode typecheck
bun run --cwd packages/sdk/js typecheck
bun typecheck
```

## 7.3 推送

```bash
# 先同步 + 校验 + 推送
./script/dev-fast.sh push
```

或手动：

```bash
git push origin HEAD
```

注意：`pre-push` 会执行 `bun typecheck`，因此推送前最好先本地跑一遍。

---

## 8. 测试与质量门禁

## 8.1 根目录测试限制

根 `package.json` 的 `test` 是保护脚本（会直接失败），避免在 monorepo 根误跑。

## 8.2 推荐测试入口

```bash
# app 单测
bun run --cwd packages/app test:unit

# app e2e（本地辅助）
bun run --cwd packages/app test:e2e:local

# opencode 单测
bun run --cwd packages/opencode test
```

## 8.3 全仓类型检查

```bash
bun typecheck
```

它会通过 `turbo` 跑多包的 `typecheck`（并依赖构建链）。

---

## 9. 核心功能实操模板

## 9.1 首次进入项目

```bash
cd /path/to/repo
opencode
/connect
/init
```

## 9.2 模型与 Agent

```text
/models
<Tab>   # 切换 build/plan 主 Agent
@general 帮我检索这个仓库里所有与 session compaction 相关逻辑
```

## 9.3 TUI 内常用操作

```text
@path/to/file.ts 解释这个文件
!git status
/sessions
/share
/unshare
/undo
/redo
```

## 9.4 自定义命令（高频重复任务）

1. 新建 `.opencode/commands/test.md`。
2. 在 frontmatter 里写 `description`、`agent`、`model`。
3. 在正文写命令模板。
4. TUI 中执行 `/test`。

## 9.5 自定义规则（团队行为统一）

1. 在项目根维护 `AGENTS.md`。
2. 对通用规则可放 `~/.config/opencode/AGENTS.md`。
3. 若需拆分多文件，使用 `opencode.json` 的 `instructions` 引用。

## 9.6 Provider 接入最短路径

1. `/connect` 配置 API key。
2. `/models` 验证模型可见。
3. 需要固定默认模型时写入 `opencode.json`：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode/gpt-5.1-codex"
}
```

## 9.7 MCP 接入最短路径

本地 MCP 示例：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "my-local-mcp": {
      "type": "local",
      "command": ["npx", "-y", "my-mcp-command"],
      "enabled": true
    }
  }
}
```

远程 MCP 示例：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "my-remote-mcp": {
      "type": "remote",
      "url": "https://example.com/mcp",
      "enabled": true
    }
  }
}
```

## 9.8 插件最短路径

1. 项目级目录：`.opencode/plugins/`。
2. 新建插件文件导出插件函数。
3. 用事件钩子实现你的逻辑（如 `tool.execute.before`）。
4. 若依赖外部包，在 `.opencode/package.json` 添加依赖。

## 9.9 Skills 最短路径

1. 新建 `.opencode/skills/<name>/SKILL.md`。
2. frontmatter 至少包含 `name`、`description`。
3. `name` 必须和目录名一致，且匹配 `^[a-z0-9]+(-[a-z0-9]+)*$`。

---

## 10. Server / SDK / API 调用实践

## 10.1 启动服务

```bash
opencode serve --port 4096 --hostname 127.0.0.1
```

查看 OpenAPI 文档：

```text
http://localhost:4096/doc
```

## 10.2 SDK 客户端示例

```ts
import { createOpencodeClient } from "@opencode-ai/sdk"

const client = createOpencodeClient({
  baseUrl: "http://localhost:4096",
})

const health = await client.global.health()
console.log(health.data.version)
```

## 10.3 什么时候需要重新生成 SDK

当你改动了 server API/OpenAPI 相关内容，执行：

```bash
./script/generate.ts
./packages/sdk/js/script/build.ts
```

---

## 11. Web 与 Desktop 使用建议

## 11.1 Web（浏览器）

```bash
opencode web --port 4096 --hostname 127.0.0.1
```

如需局域网访问：

```bash
opencode web --port 4096 --hostname 0.0.0.0 --mdns
```

生产/共享网络必须建议设置密码：

```bash
OPENCODE_SERVER_PASSWORD=your-password opencode web
```

## 11.2 Desktop（Tauri）

```bash
bun run --cwd packages/desktop tauri dev
```

遇到 desktop 问题优先检查：

1. 插件是否异常（先禁用插件）。
2. `~/.cache/opencode` 缓存是否损坏（清理后重启）。
3. `server.port` / `server.hostname` 配置是否冲突。

---

## 12. 故障排查速查

## 12.1 日志与存储位置

1. 日志：
   - macOS/Linux：`~/.local/share/opencode/log/`
   - Windows：`%USERPROFILE%\.local\share\opencode\log`
2. 状态存储：
   - macOS/Linux：`~/.local/share/opencode/`
   - Windows：`%USERPROFILE%\.local\share\opencode`

## 12.2 常见问题定位顺序

1. `git status -sb`：先确认不是脏工作区导致。
2. `bun --version`：确认版本与仓库要求接近。
3. `bun install`：依赖是否完整。
4. `bun typecheck`：先看类型错误。
5. 对应包内单测：定位功能回归。
6. 查 `~/.local/share/opencode/log/*` 获取具体报错。

## 12.3 常见修复动作

1. Provider 异常：重新 `/connect`。
2. 模型不可用：检查 `provider/model` 格式。
3. API 包异常：清理 `~/.cache/opencode` 后重启。
4. Desktop 卡死：禁用插件 + 清缓存。

---

## 13. 命令速查（建议贴终端旁）

```bash
# 安装依赖
bun install

# 核心开发入口
bun dev

# 仅 web/app
bun dev:web

# desktop
bun dev:desktop

# 同步 dev + 校验 + 推送（仓库定制）
./script/dev-fast.sh push

# 全仓类型检查
bun typecheck

# app 单测
bun run --cwd packages/app test:unit

# opencode 单测
bun run --cwd packages/opencode test

# 启动 server
opencode serve --port 4096

# 启动 web
opencode web --port 4096

# 附着 TUI
opencode attach http://localhost:4096
```

---

## 14. 新同学 30 分钟上手路径

1. `bun install`，确认 `bun --version`。
2. `bun dev` 启动并进入 TUI。
3. `/connect` + `/models` 配置模型。
4. `/init` 生成或更新 `AGENTS.md`。
5. 用 `@文件` + `!命令` + `/sessions` 跑一轮基本操作。
6. 修改一个小功能后跑 `./script/dev-fast.sh check`。
7. 最后 `./script/dev-fast.sh push` 推送。

完成以上步骤后，你已经具备在该仓库稳定协作的全部基础能力。
