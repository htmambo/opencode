# Skills 使用指南（创建、加载、权限、复用）

更新时间：2026-03-02

## 1. Skills 解决什么问题

Skill 是可复用的“能力说明包”，本质是 `SKILL.md` 文件。  
它适合沉淀：

1. 反复出现的流程（例如发布、回归检查、代码审查套路）。
2. 特定领域知识（例如公司内部架构约束）。
3. 固定工具编排习惯（例如“先 context7 再 patch”）。

与 `AGENTS.md` 的区别：

1. `AGENTS.md` 偏全局行为约束。
2. Skill 偏任务级、按需加载的能力片段。

---

## 2. 目录与发现规则（安装方式）

## 2.1 放置路径

OpenCode 会在这些位置查找 Skill：

1. 项目：`.opencode/skills/<name>/SKILL.md`
2. 全局：`~/.config/opencode/skills/<name>/SKILL.md`
3. 兼容路径：`.claude/skills`、`~/.claude/skills`
4. 兼容路径：`.agents/skills`、`~/.agents/skills`

## 2.2 发现行为

项目路径会从当前目录向上遍历到 git worktree；全局路径会一起加载。  
建议：团队共享 Skill 放项目内，个人偏好 Skill 放全局目录。

---

## 3. 创建一个 Skill

## 3.1 最小模板

文件：`.opencode/skills/git-release/SKILL.md`

```markdown
---
name: git-release
description: 生成发布说明并给出 release 命令
license: MIT
compatibility: opencode
metadata:
  audience: maintainers
---

## What I do

- 汇总提交并生成 release notes
- 建议版本号
- 输出可执行命令

## When to use me

当需要发布版本时使用。
```

## 3.2 frontmatter 允许字段

1. `name`（必填）
2. `description`（必填）
3. `license`（可选）
4. `compatibility`（可选）
5. `metadata`（可选，字符串键值）

未知字段会被忽略。

---

## 4. 命名与校验规则（必须满足）

1. 长度 1-64。
2. 小写字母数字与单个连字符。
3. 不能以 `-` 开头/结尾。
4. 不能出现连续 `--`。
5. 必须与目录名一致。

正则：

```text
^[a-z0-9]+(-[a-z0-9]+)*$
```

`description` 长度应为 1-1024。

---

## 5. 使用方式

## 5.1 自动发现与按需加载

Skill 会出现在 `skill` 工具可用列表中，模型按需加载。  
你可以在需求中明确提示模型使用某个 Skill（例如提及 skill 名称）。

## 5.2 典型提示方式

```text
请使用 git-release skill，给出本次发布说明草稿和发布命令。
```

---

## 6. 权限控制

## 6.1 全局权限

```json
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "skill": {
      "*": "allow",
      "internal-*": "deny",
      "experimental-*": "ask"
    }
  }
}
```

## 6.2 按 Agent 覆盖

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "plan": {
      "permission": {
        "skill": {
          "internal-*": "allow"
        }
      }
    }
  }
}
```

## 6.3 禁用 skill 工具

```json
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "plan": {
      "tools": {
        "skill": false
      }
    }
  }
}
```

---

## 7. 设计建议（提高复用率）

1. 一个 Skill 只做一个明确场景。
2. `description` 写“何时使用”，不要只写“做什么”。
3. 在正文里包含“触发条件 + 步骤 + 产出格式”。
4. 把依赖工具前置写清（例如需 `context7` / 需 `bash`）。
5. 团队统一命名前缀（如 `release-*`, `security-*`）。

---

## 8. 排障清单

## 8.1 Skill 没被发现

1. 文件名必须是大写 `SKILL.md`。
2. frontmatter 是否包含 `name` 与 `description`。
3. `name` 与目录名是否一致。
4. 是否被权限 `deny` 隐藏。

## 8.2 Skill 被发现但不生效

1. 看当前 Agent 是否禁用了 `skill` 工具。
2. 检查是否有更高优先级配置覆盖。
3. 在提示里显式点名 Skill 再观察行为。

---

## 9. 关联文档

1. [工具索引](./INDEX.zh-CN.md)
2. [MCP 指南](./MCP.zh-CN.md)
3. [LSP 指南](./LSP.zh-CN.md)
4. [Custom Tools 与 Plugins](./CUSTOM_TOOLS_AND_PLUGINS.zh-CN.md)
5. [权限策略](./PERMISSIONS.zh-CN.md)

