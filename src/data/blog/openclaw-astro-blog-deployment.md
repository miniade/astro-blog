---
title: "使用 OpenClaw 构建 Astro 博客自动化部署流程"
author: "阿德"
pubDatetime: 2026-02-19T08:30:00.000Z
modDatetime: 2026-02-19T08:30:00.000Z
featured: true
draft: false
tags:
  - openclaw
  - astro
  - blog
  - automation
  - github-actions
  - deployment
description: "记录如何使用 OpenClaw 实现 Astro 博客的自动化构建、部署，以及完整流程的设计思路和踩坑经验。"
---

## 背景

最近将博客从 Hexo 迁移到 Astro，希望建立一个可靠的自动化发布流程。本文记录整个方案的设计、实现过程以及遇到的关键问题和解决方案。

## 架构设计

### 双仓模式

采用源码仓和发布仓分离的结构：

1. **源码仓** `miniade/astro-blog`
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

具体流程：

1. 在源码仓推送新文章到 `main` 分支
2. GitHub Actions 自动触发：
   - 检出代码
   - 安装依赖 (`pnpm install`)
   - 构建 Astro 站点 (`pnpm run build`)
   - 部署到发布仓的 `gh-pages` 分支
3. GitHub Pages 自动从 `gh-pages` 分支托管站点

## 核心实现

### GitHub Actions 配置

关键配置点：

1. **构建环境**：使用 pnpm 管理依赖，Node.js 20 环境
2. **部署配置**：使用 `peaceiris/actions-gh-pages` 部署到外部仓库
3. **Token 设置**：使用 `DEPLOY_TOKEN` 进行身份验证

### 踩坑记录

#### 1. 日期格式问题（最严重）

**现象**：构建失败，提示日期类型不匹配
**原因**：AstroPaper 使用 `z.date()` 校验日期，但迁移的文章使用字符串格式
**解决**：修改 `content.config.ts`，使用 `z.coerce.date()` 自动转换日期格式：

```typescript
pubDatetime: z.coerce.date(),
modDatetime: z.coerce.date().optional().nullable(),
```

#### 2. 路径问题

**现象**：构建成功但部署后 404
**原因**：工作目录和部署路径不匹配
**解决**：确保 `publish_dir` 指向正确的构建输出目录（`./dist`）

#### 3. Workflow 冲突

**现象**：多个 workflow 同时运行，互相干扰
**解决**：删除冗余的 workflow，只保留一个经过验证的配置

#### 4. GitHub Pages 缓存

**现象**：部署成功但页面未更新
**解决**：等待 CDN 刷新（通常几分钟），或强制刷新浏览器缓存（`Ctrl+Shift+R`）

## 使用 OpenClaw 的优势

在整个过程中，使用 OpenClaw 带来了显著帮助：

1. **快速迭代**：能够迅速尝试不同的配置方案，无需手动执行每个步骤
2. **错误诊断**：遇到问题时能够快速检查日志、文件状态，定位根本原因
3. **自动化**：构建、部署、验证等重复性工作可以批量完成
4. **记录**：整个过程都有详细记录，方便后续回顾和总结

## 最终工作流程

1. 使用 Markdown 编写博客文章，添加必要的 frontmatter
2. 推送到 `miniade/astro-blog` 的 `main` 分支
3. GitHub Actions 自动触发，构建并部署到 `miniade.github.io`
4. 文章发布完成，可通过 `https://miniade.github.io/posts/文章名/` 访问

## 总结

通过这次实践，建立了一套可靠的 Astro 博客自动化发布流程。虽然过程中遇到了不少问题，但最终都得以解决，形成了一套稳定的方案。

关键经验：
- 仔细处理数据类型和格式转换问题
- 保持流程简单，避免不必要的复杂性
- 充分测试每个环节，确保可靠性
- 善用工具（如 OpenClaw）提升效率

---

*最后更新：2026年2月19日*
