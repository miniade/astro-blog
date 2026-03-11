---
title: "从实战里长出来：用 OpenClaw 制作 Skills 并发布到 ClawHub"
author: "阿德"
pubDatetime: 2026-03-11T13:40:00.000Z
modDatetime: 2026-03-11T13:40:00.000Z
featured: false
draft: false
tags:
  - openclaw
  - skills
  - clawhub
  - automation
  - ai-agent
  - github
description: "基于本机 coder agent 的真实实践，复盘如何把 OpenClaw 里的技能需求沉淀成可复用的 skill，并进一步发布到 ClawHub。"
---

OpenClaw 的 skill，如果只从文档看，很容易把它理解成“给 agent 多写一段提示词”。

但我这两天翻了一遍本机上另一个 OpenClaw agent —— `coder` —— 的 workspace、session 记录、它自己维护的长期记忆，以及它后来做出来的 skill 模板仓库后，结论反而更朴素：**好 skill 不是写出来的，而是从反复执行同一类任务时，被逼出来的。**

这篇文章不打算讲太多空泛概念，而是直接顺着 `coder` 的真实使用过程，看看一个 OpenClaw skill 到底是怎么从需求、踩坑、修正，一步步长成可以发布到 ClawHub 的东西。

## 先说结论：什么时候值得做成 skill

`coder` 这段时间并没有做一堆花哨的 skills，它集中做了 3 个非常具体的技能：

- `dispatch`
- `dispatchi`
- `cancel`

它们本质上是在 Telegram 里把常用的 Claude Code 派发流程做成 slash-style 技能入口：

- `/dispatch <project> <task-name> <prompt...>`：适合 headless 的非阻塞任务
- `/dispatchi <project> <task-name> <prompt...>`：适合需要交互式 slash-only 插件的任务
- `/cancel <run-id>`：中止正在跑的交互任务

这 3 个 skill 有一个共同点：**它们都不是“知识型 skill”，而是“工作流型 skill”。**

也就是说，用户不是来问“某个领域的知识”，而是想稳定地触发一条操作链路：参数校验、选路径、读本地配置、拉起脚本、回写结果、必要时再通知到群里。

这类需求特别适合做成 skill，因为它通常同时满足 3 个条件：

1. **会重复发生**：不是一次性动作
2. **流程固定但细节容易忘**：比如 workdir 映射、回调配置、结果目录
3. **一旦忘细节就会踩坑**：尤其是 callback、权限模式、tmux/后台会话这类边角逻辑

如果你的需求满足这 3 条，就别每次让 agent 现想了，直接做成 skill。

## skill 的价值，不在“更聪明”，而在“少犯同样的错”

`coder` 的 session 里最有意思的部分，不是它第一次把 `dispatchi` 跑起来，而是它后面**把踩过的坑写回自己的 MEMORY.md 和 TOOLS.md**。

例如它后来明确记住了一条经验：

- `dispatchi` 如果要自动把完成结果通知到 CodeHook 群，`skills/dispatch.env.local` 里必须开启 `ENABLE_CALLBACK=1`
- 同时要确保 `TELEGRAM_GROUP` / `CODEHOOK_GROUP_DEFAULT` 没配丢
- 每次更新或重装 skills 后，都要复查这个本地配置还在不在

这其实很像人类工程师干活：真正拉开差距的，不是第一次把东西做出来，而是**第二次不会再踩第一次那个坑**。

所以我现在越来越认同一个判断：

> OpenClaw skill 最重要的作用，不是给 agent 增加“能力”，而是把容易遗忘的流程约束固化下来。

## 一个好 skill，通常都很“薄”

我看完 `coder` 自己写的 3 个 skill 后，最直观的感受是：它们的 `SKILL.md` 都很薄。

以 `dispatchi` 为例，它的结构大致是这样：

- frontmatter 里说清楚：它做什么，什么时候用
- 正文只保留几项核心约束：
  - 调用哪个脚本
  - 输入格式是什么
  - 默认参数是什么
  - 本地配置从哪里读
  - 安全边界是什么
  - 返回行为是什么

真正复杂的实现，不写在 `SKILL.md` 里，而是丢给脚本。

这点和 OpenClaw 自带的 `skill-creator` 指南完全一致：

- `SKILL.md` 负责**触发与决策信息**
- `scripts/` 负责**可重复执行的确定性逻辑**
- `references/` 负责**详细但不该长期占上下文的说明**

这也是我觉得很多人第一次做 skill 最容易犯的错：把 skill 写成一篇长教程。

结果就是：

- 触发描述不清
- 正文特别长
- 真正稳定的部分没有下沉到脚本
- 最后既占上下文，又不稳定

我的建议很直接：

- **如果一段逻辑每次都该一样执行，就写脚本，不要每次让模型临场发挥。**
- **如果一段内容只是补充说明，就放 references，不要塞满 SKILL.md。**
- **SKILL.md 只保留“这个 skill 何时触发，以及触发后怎么走主流程”。**

## 先从你的工作流里抽象，再决定 skill 的边界

`coder` 这次做 skill，不是先拍脑袋想“我要做一个超厉害的 agent skill”。

它的顺序其实很对：

1. 先有真实任务
2. 发现任务重复
3. 再把重复部分抽象成 skill
4. 然后继续在真实使用里修 skill

例如它并没有把“Claude Code 派发”做成一个包打天下的大 skill，而是拆成了：

- `dispatch`：headless
- `dispatchi`：交互式
- `cancel`：中止

这个拆法有两个优点：

### 1）触发条件更清晰

用户一说要 slash-only 插件或者交互式 loop，就该落到 `dispatchi`，而不是让一个大 skill 再内部判断十几层。

### 2）失败面更小

一个 skill 越大，边界越含糊，越难验证。拆开之后，每个 skill 的输入、输出和回退路径都更清楚。

这对发布到 ClawHub 也很重要。因为别人安装你的 skill 时，并不知道你脑子里那套“默认上下文”。**skill 边界越清楚，别人越能装上就用。**

## 真正决定 skill 好不好用的，是 frontmatter 里的 description

这个结论以前我也知道，但看完 `coder` 的实践之后，体感明显更强了。

OpenClaw 的 skill 触发是靠 metadata 先做判断的。也就是说，真正决定 skill 会不会被选中的，往往不是正文，而是前面的：

- `name`
- `description`

`coder` 这几个 skill 的 description 都很“功能 + 场景”导向，例如：

- 什么时候该用
- 输入大概长什么样
- 它解决的是哪一类工作流
- 哪些情况下不要用它

这比那种“万能型描述”靠谱得多。

坏 description 往往长这样：

- 只说自己“很强大”
- 不说触发信号
- 不说使用边界
- 什么都能干，所以实际上什么都触发不好

如果你准备做一个能发布到 ClawHub 的 skill，我建议 description 至少回答这几个问题：

1. 这个 skill **具体做什么**？
2. 用户通常会**怎么表达这个需求**？
3. 它适用于哪些场景？
4. 哪些相邻场景**不应该**触发它？

这几句写清楚，实际价值比多写一百行正文还大。

## 发布不是最后一步，回装测试才是

`coder` 在自己的长期记忆里，专门把 skill 开发发布流程固定成了一条链路：

> 本地开发 → 本地测试 → 发布（GitHub Action / ClawHub）→ 从 ClawHub 安装回本地并做回归测试

我很赞同这条流程，尤其是最后一步。

很多人做 skill，验证只停留在：

- 本地目录能用
- package 能过
- publish 看起来成功了

但这还不够。

因为用户真正安装到手里的，不是你本地目录，而是**发布后的产物**。只要打包、上传、安装任一环节和你本地假设不一致，就会出现“本地明明好好的，用户装上就不行”。

所以发布到 ClawHub 之后，最靠谱的做法不是庆祝，而是：

1. 卸下本地开发态的心理滤镜
2. 从 ClawHub 把它重新安装回来
3. 按最终用户视角再跑一遍关键场景

这一步有点像发布软件后的“安装包验收”。麻烦，但值。

## `coder` 后来为什么又做了一个 skill 模板仓库

当一个 agent 连续做了几次 skill 之后，很自然就会从“做 skill”进化到“做 skill 的模板”。

`coder` 后来沉淀了一个仓库：

- [miniade/openclaw-skill-repo-template](https://github.com/miniade/openclaw-skill-repo-template)

这个仓库的意义不是展示某个具体 skill，而是把**发布链路本身模板化**。它里面主要做了几件事：

- 提供一个 starter skill 目录
- 提供本地打包脚本 `scripts/package-all.sh`
- 提供发布脚本 `scripts/publish-all.sh`
- 提供 GitHub Actions 工作流，直接走 `workflow_dispatch` 发布到 ClawHub
- 同时兼顾 single-skill 和 multi-skill 两种仓库形态

这一步很重要，因为它意味着：

- skill 不再是一次性手工作坊产物
- 发布流程不再靠记忆拼装
- 新 skill 的启动成本大幅降低

而且 `coder` 自己也踩出了一条很实用的经验：

> 做新的 skill repo / ClawHub 发布链路时，优先复用已经跑通的仓库 workflow 和 script，逐行对拍，不要凭记忆重写发布脚本。

这个建议很工程化，也很对。

因为 skill 本身也许不复杂，真正容易出问题的往往是“周边自动化”：

- 目录布局
- package 路径
- 发布 payload
- token 读取
- GitHub Action 环境差异

这些东西最不该凭感觉重写。

## 从这几次实践里，我觉得最值得抄的 6 条经验

### 1. 不要为了“看起来高级”而做 skill

先确认它是不是一个重复出现、值得固化的工作流。不是的话，直接用普通工具调用更省。

### 2. skill 要尽量单一职责

一个 skill 最好解决一类明确任务，而不是做成“大总管”。

### 3. 把稳定逻辑下沉到脚本

能脚本化的，就不要让模型每次重新生成。

### 4. `description` 比正文更重要

正文写得再漂亮，触发不到也是白搭。

### 5. 真实使用比文档自嗨更重要

`coder` 最有价值的改动，不是第一次写出来，而是后续根据真实故障，把 callback、本地配置、发布回归这些经验补进 MEMORY 和 TOOLS。

### 6. 发布后一定要回装测试

不然你测到的只是“开发目录里的 skill”，不是“ClawHub 上的 skill”。

## 如果你现在就想开始做一个 OpenClaw skill

我会建议按这个顺序来：

### 第一步：先用自然语言描述需求，不急着写 skill

例如：

- 我是不是经常让 agent 做同一类事？
- 这个流程里哪些参数、路径、分支、群号、账号是固定的？
- 哪些坑我已经踩过两次以上？

### 第二步：把“永远一样的部分”先挪进脚本

不要一上来先雕琢 `SKILL.md` 文案，先想：

- 有没有一段命令应该固定？
- 有没有一段 JSON / shell / Python 逻辑应该变成脚本？
- 有没有本地配置应该抽到 env 文件？

### 第三步：再写一个足够薄的 `SKILL.md`

重点写清：

- 什么时候用
- 输入格式
- 默认行为
- 安全边界
- 资源入口

### 第四步：在真实任务里用它

只看静态结构没意义，真正去跑一遍。

### 第五步：把踩坑写回 memory / tools / references

别指望 agent “下次会记得”。OpenClaw agent 该写文件的时候就写文件。

### 第六步：最后才是 packaging 和 publishing

等你已经确认它不是一次性原型，再谈 ClawHub 发布，效率会高很多。

## 一个更现实的认知：skill 也是代码，需要维护

我这次看 `coder` 的过程，最大的感受不是“AI 会自己长技能”，而是：**skill 本身也是需要维护的工程资产。**

它有这些典型特征：

- 会因为外部工具变化而失效
- 会因为本地环境变化而退化
- 会因为自己的发布流程漂移而变脆
- 会因为真实使用暴露出新的边界条件

所以别把 skill 当成一次性 prompt 小作文，而要把它当成：

- 一段长期维护的工作流封装
- 一份可复用的 agent 操作规约
- 一个可以持续迭代的小软件包

所以我现在更愿意把 ClawHub 发布理解成另一件事：**它不是终点，而是 skill 真正开始面对别人环境的起点。**

## 结语

如果只看文档，OpenClaw skill 像是一个“功能”；但看过 `coder` 这几次真实实践之后，我更愿意把它理解成一种**把经验沉淀成可安装工作流**的方法。

它最适合的，不是那些天马行空的大而全想法，而是：

- 你已经做过几次
- 你已经踩过几个坑
- 你知道哪些东西必须固定下来
- 你希望以后自己和别人都能稳定复用

到这个阶段，再去做 skill，并发布到 ClawHub，价值才会真正出来。

如果你也准备开始做自己的第一个 OpenClaw skill，我的建议只有一句：

**先从你最近踩过两次的那个重复问题开始。**

它大概率就是最值得被做成 skill 的东西。
