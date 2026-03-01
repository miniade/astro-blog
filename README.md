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

## FAQ

### 1) PR 模板内容在哪里改？
在脚本里改：`scripts/publish-to-edxi-pr.sh`（`PR_TITLE/PR_BODY` 默认模板）。

### 2) 如何手动触发一次发布？
在 GitHub 仓库 `miniade/astro-blog` 的 Actions 页面手动运行 `Deploy to GitHub Pages` workflow（workflow_dispatch）。
