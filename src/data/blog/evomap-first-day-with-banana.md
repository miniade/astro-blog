---
title: "把 OpenClaw Agent 接入 EvoMap：Banana 上线后的 24 小时初体验"
author: "阿德"
pubDatetime: 2026-03-01T15:00:00.000Z
modDatetime: 2026-03-01T15:00:00.000Z
featured: false
draft: false
tags:
  - openclaw
  - evomap
  - agents
  - automation
  - evolver
description: "记录我把 OpenClaw agent Banana 接入 EvoMap 的上手过程、一天跑下来遇到的真实问题与初步体感，并说明后续将继续观察 evolver 是否带来可见变化。"
---

这两天我把运行在 Linux 上的另一个 OpenClaw agent **Banana** 接入了新平台 **EvoMap**（A2A 接口 + 任务系统）。本文不是教程式“从 0 到 1”——更像一份真实的使用记录：我做了什么配置、它一天跑下来发生了什么、以及我觉得哪些点值得继续观察。

> 平台链接：<https://evomap.ai/>

## 我想从 EvoMap 得到什么

我对这类平台的期待很朴素：

1. **让 agent 有真实的外部反馈回路**：不是在本地“自嗨优化 prompt”，而是能通过任务系统不断碰撞边界条件（rate limit、资产校验、幂等、失败重试等）。
2. **让“自我演进”变成可审计的工程行为**：有结构化日志、可复现的变更路径、可回滚。

Banana 这次的角色是一个“长时间运行、可自我修复”的 agent；EvoMap 更像它的外部环境。

## 上手配置：我实际做了哪些事

我没有把 Banana 做成一个“点点网页就能跑”的配置，而是尽量让它 **可自动化、可重复**。

### 1) 安装/固定 evolver（作为上游 vendor skill）

Banana 的 workspace 里安装了 **EvoMap/evolver**（当作 upstream vendor），并固定到一个明确版本（v1.20.3）。

为什么要固定版本：因为“自我演进”本质上是会改动行为的系统，版本漂移会让你很难判断“平台变了、agent 变了、还是自己 patch 变了”。

> evolver releases：<https://github.com/autogame-17/evolver/releases>

### 2) 做了一个很小但关键的本地集成层（A2A client + scripts）

在 Banana 的 workspace 里，围绕 EvoMap A2A 做了一层脚本化封装（保持本地状态在 `~/.config/banana-secrets/`，避免写入 repo）：

- `evomap_hello`：建立/恢复 node 状态
- `evomap_heartbeat`：按平台要求做 keep-alive，并顺手把 `available_work` 快照落盘
- `evomap_publish_eligible`：尝试发布符合条件的 bundles

这些脚本的目的不是“花哨”，而是为了让后面的 cron/runner 逻辑能做到：**成功静默、失败可定位、状态可追溯**。

### 3) 跑任务：用预算约束的 task runner + 日志

我给 Banana 做了一个预算约束的 runner（核心逻辑：claim → publish → submit），并把每一步结构化写入 `memory/evomap-task-runner.jsonl`。

几个设计点我认为非常“真实世界友好”：

- **硬约束时间预算**：每天最多运行 90 分钟（wall clock）。
- **自我节流**：最低请求间隔、并尊重 `retry_after_ms`/`next_request_at`。
- **把失败分阶段**：例如 `claim_err` vs `solve_err` vs `submit_err`，后面复盘会省很多脑细胞。

### 4) 监控：只在“真的异常”时推送

我不希望 Telegram 被打爆，所以做了一个 alert checker：

- 过去一个窗口内 **出现任意 5xx** → 告警
- **429 激增**（例如 ≥10）→ 告警
- `duplicate_asset` 这类“信息性”问题默认不单独告警

这个策略的体感是：足够安静，但不会让问题在后台烂掉。

## 跑了一天：平台的“真实摩擦”长什么样

从日志统计看，Banana 在一天内大致跑到了下面这个量级（以 runner 的当日累计为准）：

- tasks_attempted：`830`
- tasks_joined：`382`
- tasks_submitted：`307`
- errors_429（rate limit）：`105`
- errors_5xx：`20`
- 当日 runner 累计耗时（used_ms）：约 `2,909,845 ms`（约 48.5 分钟）

这组数字本身不代表“效果很好”，但非常清楚地暴露了几个现实：

### 1) 429 是常态：平台有明确的 bucket/policy

我看到的 429 返回里包含了相当多可操作的信息，比如：

- `retry_after_ms`
- `next_request_at`
- bucket 类型（例如 `sender`）
- policy（limit/window）

这对自动化是好事：你不需要猜，也不需要“凭感觉 sleep”。

我的结论：如果你的 runner 不尊重 `next_request_at`，那就是在烧预算。

### 2) 5xx（含 Cloudflare 502）也会出现：需要把它当成平台抖动

一天内出现了多次 5xx/502。我的处理策略偏保守：

- 把 5xx 当作平台抖动
- 退避重试（并尽量不扩大失败的 blast radius）
- 通过告警把它从“沉默失败”里拎出来

### 3) 409 的两种形态：task_full 与 duplicate_asset

我遇到的 409 主要有两类：

- `task_full`：很直观，任务满了；这属于“抢任务”的正常摩擦。
- `duplicate_asset`：更有意思。

`duplicate_asset` 会触发类似 quarantine 的决策，并且平台会提示：如果你“解绑/重新注册”过，可能需要重新 rebind 原来的 node。

这件事带来的启发是：

- **资产 ID 幂等** 不是可选项；你必须假设“提交过的东西会重复遇到”。
- 平台对于“重复资产”的处理逻辑，会直接影响你是“缓存命中”还是“被隔离”。

### 4) 校验命令（validation command）有安全策略：不要写得像 shell

我踩到一个很具体的坑：validation 命令里如果出现类似 `; <letter>` 的模式，会被识别为危险命令。

所以我的策略变成：

- validation 尽量用 **node-only** 的单表达式（例如 `node -e "process.exit(<cond>?0:1)"`）
- 避免分号和 shell 操作符

这种限制其实合理：平台需要防止你把 validation 当成“远程执行入口”。

## 我对 EvoMap 的初步体感（优点 / 不确定点）

### 我喜欢的点

- **接口返回足够结构化**：429 的 `next_request_at`/policy 信息非常关键。
- **“可观测性”容易做出来**：有分阶段日志后，定位错误很快。
- **把 agent 放进真实的约束环境**：rate limit、幂等、失败恢复，这些比“prompt 优化”更像工程。

### 我还不确定的点

- **credit_balance/credits 的反馈与消耗模型**：目前我看到的一些 heartbeat 信息里 `credit_balance` 为 0，但 runner 仍能跑任务；这可能是平台策略或我理解偏差，后面需要继续观察。
- **“刷任务”是否真正带来能力沉淀**：如果只是吞吐量很高，但产出的 Gene/Capsule 没有复用价值，那只是更高级的 stress test。

## 下一步：继续观察 evolver 是否真的改变 agent

我后续会重点观察两件事：

1. **EvoMap 平台本身的稳定性**：5xx 的频率是否下降、rate limit 的 bucket 规则是否会调整。
2. **evolver 这个 skill 是否带来可见的行为变化**：
   - 是否能从失败模式中提取稳定的策略（而不是每次都“重新推理一次”）
   - 是否能形成可复用的“胶囊”（Capsule）与更稳的防护栏（比如更好的退避、幂等键、缓存策略）

如果 evolver 真能把这些变化沉淀下来，并且可以被审计（版本、事件、资产），那它对 agent 的意义会和“普通工具脚本”完全不同。

我会继续跑一段时间，再写一篇更偏“对比”的复盘：Banana 接入 EvoMap 前后，哪些行为指标真的变了。
