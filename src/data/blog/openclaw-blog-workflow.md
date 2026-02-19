---
title: "基于 OpenClaw 的博客自动化发布方案"
author: "阿德"
pubDatetime: 2026-02-18T12:30:00.000Z
modDatetime: 2026-02-18T12:30:00.000Z
featured: true
draft: false
tags:
  - openclaw
  - blog
  - automation
  - github-actions
  - astro
description: "记录如何使用 OpenClaw 实现博客的自动化构建和部署，以及整个流程的设计和踩坑经验。"
---

## 背景

最近将博客从 Hexo 迁移到了 Astro，并希望实现自动化的发布流程。本文记录了整个方案的设计、实现过程以及遇到的问题。

## 方案架构

### 仓库结构

采用双仓模式：

1. **源码仓**: `miniade/edxi-blog-astro`
   - Astro 博客源码
   - Markdown 文章
   - 主题配置

2. **发布仓**: `miniade/miniade.github.io`
   - GitHub Pages 托管
   - 构建后的静态文件
   - 实际对外服务的站点

### 工作流程

```
推送文章 → GitHub Actions 构建 → 部署到发布仓 → GitHub Pages 托管
```

### 自动化流程

1. 在源码仓推送新文章到 `main` 分支
2. GitHub Actions 自动触发：
   - 检出代码
   - 安装依赖 (`npm ci`)
   - 构建 Astro 站点 (`npm run build`)
   - 部署到发布仓的 `gh-pages` 分支
3. GitHub Pages 自动从 `gh-pages` 分支托管站点

## 技术细节

### GitHub Actions 配置

关键配置点：

1. **工作目录设置**: 由于项目实际在 `edxi-blog-astro/` 子目录中，需要设置 `defaults.run.working-directory`
2. **部署路径**: `publish_dir` 需要指向正确的构建输出目录
3. **Personal Access Token**: 使用 `DEPLOY_TOKEN` 进行身份验证

### 遇到的坑

1. **路径问题**: 最初没有正确设置 `working-directory`，导致构建找不到文件
2. **部署目录不匹配**: `publish_dir` 路径错误，导致部署失败
3. **Workflow 冲突**: 多个 workflow 文件相互干扰，需要清理

## 使用 OpenClaw 的优势

在整个过程中，使用 OpenClaw 带来了显著的优势：

1. **自动化**: 无需手动执行每个步骤，减少了重复劳动
2. **快速迭代**: 能够快速尝试不同的配置方案
3. **错误处理**: 遇到问题时能够快速诊断和修复
4. **记录**: 整个过程都有记录，方便后续回顾和学习

## 总结

通过这次的实践，建立了一套完整的博客自动化发布流程。虽然过程中遇到了不少问题，但最终都得以解决，形成了一套可靠的方案。

关键经验：
- 仔细配置 GitHub Actions 的路径和工作目录
- 保持流程简单，避免不必要的复杂性
- 充分测试每个环节，确保可靠性
- 善用工具（如 OpenClaw）提升效率

---

*最后更新：2026年2月18日*
