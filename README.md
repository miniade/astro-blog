# astro-blog (miniade)

这个仓库是 **miniade 的博客源代码仓库**（Astro + pnpm）。

- 你在这里写 Markdown 文章
- GitHub Actions 会自动构建静态站点并发布到：
  - `miniade/miniade.github.io:master`（给 miniade.github.io 使用；deploy 采用 `force_orphan: true`）
  - 同时维护一个用于给上游提交 PR 的固定分支：`miniade/miniade.github.io:pr-to-edxi`
  - 并自动创建/更新 PR 到 `edxi/edxi.github.io:master`

> 主题官方文档已移到：[`README-AstroPaper.md`](./README-AstroPaper.md)

---

## 给后续写博客的 Agent 的工作指南

### A. 写新文章（最常用）

文章目录：

- `src/data/blog/*.md`

每篇文章是一个 markdown 文件，开头需要 frontmatter（示例）：

```md
---
author: miniade
pubDatetime: "2026-03-01T00:00:00Z"
title: 标题
slug: my-post-slug
featured: false
draft: false
tags:
  - openclaw
  - notes
description: 一句话摘要（用于列表/SEO）
canonicalURL: ""  # 可选：如果这篇是转载/迁移文章，填原文链接
---

正文从这里开始...
```

约定：
- **新文章**：`canonicalURL` 留空即可
- `draft: true` 的文章不会出现在发布站点
- `slug` 用于 URL（通常对应 `/posts/<slug>/`）

### B. 本地预览/检查

本地开发命令：

```bash
pnpm install
pnpm run dev
```

构建/校验（提交前建议跑一次）：

```bash
pnpm run build
```

> 说明：pnpm 可能提示 “Ignored build scripts: esbuild, sharp”。在本仓库的 CI/Action 构建是可通过的；如果你在本地遇到 native 依赖相关问题，再按提示运行 `pnpm approve-builds` 进行允许即可。

### C. 发布流程（你只需要 push）

发布是 **GitHub Actions 自动完成** 的：

- 对 `main`（或 `master`）的 push 会触发 `.github/workflows/deploy.yml`
- 该 workflow 会：
  1) `pnpm install` + `pnpm run build`
  2) 发布 `./dist` 到 `miniade/miniade.github.io:master`（`force_orphan: true`）
  3) 运行 `./scripts/publish-to-edxi-pr.sh`：
     - 把 `dist/` 覆盖写入 `miniade/miniade.github.io:pr-to-edxi`
     - 如果上游 `edxi/edxi.github.io` 没有 open PR（head=miniade:pr-to-edxi），就自动创建；有则复用并更新

你要做的事情：
- 写文章 → `git commit` → `git push`
- 然后去上游 PR 看是否需要 edxi 账号合并

### D. 不要做的事（避免踩坑）

- 不要尝试把 `miniade/miniade.github.io:master` 用来给上游提 PR。
  - 因为它是 `force_orphan` 的发布分支，和 `edxi/edxi.github.io:master` **没有共同祖先**，GitHub 无法正常 compare/PR。
- 给上游提 PR 只用固定分支：`miniade/miniade.github.io:pr-to-edxi`

---


## 写作规范建议（可按内容灵活调整）

下面是从当前仓库已有文章总结出来的**建议**，目的是让站点风格更一致、迁移文章更好管理；但不是强制规则。遇到内容特殊（长文/翻译/系列/转载/公告）可以灵活调整。

### 1) 文件命名与 slug

现有文章大致有两类：

- **历史迁移文章**：通常保留原站点的 `slug`（例如 `hello-world`、`PowerShell_Study`），并填写 `canonicalURL` 指向原文。
- **新写文章**：建议使用更稳定的英文/拼音 slug（全小写 + `-`），避免未来改标题导致 URL 变化。

建议：
- `src/data/blog/<slug>.md` 与 frontmatter 里的 `slug:` 保持一致（便于搜索和维护）。
- slug 尽量不要频繁改动；如果必须改，建议保留 `canonicalURL`（若是迁移/转载）或在正文提示旧链接。

### 2) 日期字段（pubDatetime / modDatetime）

仓库里你会看到两种写法：
- 字符串：`pubDatetime: "2017-08-23T21:40:25Z"`
- ISO 时间：`pubDatetime: 2026-02-18T10:00:00.000Z`

建议：
- 新文章优先用 ISO（带 `Z` 的 UTC 时间），并在更新文章时设置 `modDatetime`。
- 迁移文章尽量保留原始发布时间，避免文章排序变化。

### 3) 图片与资源（尽量避免外链失效）

已有文章里存在大量外链图片（例如 `http://.../static/images/...`）。长期来看外链可能失效，影响阅读体验。

建议：
- **新文章**尽量把图片放到本仓库里再引用（例如放到 `src/assets/images/` 或 `public/` 下），避免依赖不稳定外链。
- 如果必须外链：优先用 https、并考虑在正文提供备选链接。

### 4) tags / description 的使用

建议：
- `description` 保持 1-2 句话，方便列表页/SEO。
- `tags` 用少量、稳定的标签（比如 `openclaw`、`astro`、`deployment`、`powershell`），避免大小写混用导致分裂（例如 `iTop` vs `itop` 这类情况可按需要统一）。


## FAQ

### 1) PR 模板内容在哪里改？
在脚本里改：`scripts/publish-to-edxi-pr.sh`（`PR_TITLE/PR_BODY` 默认模板）。

### 2) 如何手动触发一次发布？
在 GitHub 仓库 `miniade/astro-blog` 的 Actions 页面手动运行 `Deploy to GitHub Pages` workflow（workflow_dispatch）。
