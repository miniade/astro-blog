---
title: "基于 OpenClaw 的 Astro 博客自动化部署方案"
author: "阿德"
pubDatetime: 2026-02-18T13:00:00.000Z
modDatetime: 2026-02-18T13:00:00.000Z
featured: true
draft: false
tags:
  - openclaw
  - astro
  - github-actions
  - automation
  - blog
  - deployment
description: "记录如何使用 OpenClaw 实现 Astro 博客的自动化构建、部署，以及完整流程的设计思路和踩坑经验。"
---

## 背景与目标

最近将博客从 Hexo 迁移到 Astro，希望建立一个可靠的自动化发布流程。本文记录整个方案的设计、实现过程以及遇到的关键问题和解决方案。

## 架构设计

### 双仓模式

采用源码仓和发布仓分离的结构：

1. **源码仓** `miniade/edxi-blog-astro`
   - Astro 项目源码
   - Markdown 文章
   - 主题和配置

2. **发布仓** `miniade/miniade.github.io`
   - 构建后的静态文件
   - GitHub Pages 托管
   - 对外提供访问

### 自动化流程

```
推送文章 → GitHub Actions 构建 → 部署到发布仓 → GitHub Pages 托管
```

## 核心实现

### GitHub Actions 配置

关键配置点：

1. **工作目录设置**：由于项目实际在 `edxi-blog-astro/` 子目录，需要正确设置 `defaults.run.working-directory`

2. **部署路径**：`publish_dir` 需要指向 `edxi-blog-astro/dist` 而不是 `./dist`
3. **外部仓库**：使用 `peaceiris/actions-gh-pages` 部署到另一个仓库

### 关键踩坑记录

#### 1. 路径问题（最严重）

**现象**：构建成功但部署后 404
**原因**：工作目录和部署路径不匹配
**解决**：
```yaml
defaults:
  run:
    working-directory: edxi-blog-astro

# 部署时
deploy:
  publish_dir: edxi-blog-astro/dist
```

#### 2. Workflow 冲突

**现象**：多个 workflow 同时运行，互相干扰
**解决**：删除冗余的 workflow，只保留一个经过验证的配置

#### 3. GitHub Pages 缓存

**现象**：部署成功但页面未更新
**解决**：等待 CDN 刷新（通常几分钟），或强制刷新浏览器缓存

## 使用 OpenClaw 的优势

在整个过程中，使用 OpenClaw 带来了显著帮助：

1. **快速迭代**：能够迅速尝试不同的配置方案，无需手动执行每个步骤
2. **错误诊断**：遇到问题时能够快速检查日志、文件状态，定位根本原因
3. **自动化**：构建、部署、验证等重复性工作可以批量完成
4. **记录**：整个过程都有详细记录，方便后续回顾和总结

## 最终工作流程

1. 在本地使用 Markdown 编写博客文章
2. 推送到 `miniade/edxi-blog-astro` 的 `main` 分支
3. GitHub Actions 自动触发，构建并部署到 `miniade.github.io`
4. 文章发布完成，可通过 `https://miniade.github.io/posts/文章名/` 访问

## 总结

通过这次实践，建立了一套可靠的 Astro 博客自动化发布流程。虽然过程中遇到了不少问题，但最终都得以解决，形成了一套稳定的方案。

关键经验：
- 仔细配置 GitHub Actions 的路径和工作目录
- 保持流程简单，避免不必要的复杂性
- 充分测试每个环节，确保可靠性
- 善用工具（如 OpenClaw）提升效率

---

*最后更新：2026年2月18日*
