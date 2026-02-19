---
author: edxi
pubDatetime: "2017-08-31T18:30:00Z"
title: 阿德和有米写故事--github使用案例
slug: ade_xiyoumi_write_story_github_example
featured: false
draft: false
tags:
  - github
description: 故事梗概故事是这样滴  ade心血来潮新建了个github的repo(仓库)， 然后在repo里乱七八糟的写了点东西后提交(commit)进repo， 好奇的xiyoumi小朋友发现了这个repo，于是把repo在自己的github上做了个副本(fork)， xiyoumi小朋友把里面的东西做了点修改，也做了自己的提交， xiyoumi小朋友想把自己改的东西
canonicalURL: "https://edxi.github.io/2017/08/31/ade_xiyoumi_write_story_github_example/"
---

### 故事梗概

故事是这样滴

> ade心血来潮新建了个github的repo(仓库)，
> 
> 然后在repo里乱七八糟的写了点东西后提交(commit)进repo，
> 
> 好奇的xiyoumi小朋友发现了这个repo，于是把repo在自己的github上做了个副本(fork)，
> 
> xiyoumi小朋友把里面的东西做了点修改，也做了自己的提交，
> 
> xiyoumi小朋友想把自己改的东西也合并到ade的repo里，于是提交了pull request，
> 
> ade看了下pull request，觉得修改的不错，于是就合并进了repo，
> 
> xiyoumi小朋友大受鼓舞，又修改了好多东西，并再次提交pull request，
> 
> ade看到这次的pull request，也不知道这样改好不好，于是ade索性新建了个test分支(branch)，并在pull request里留言告诉xiyoumi，让他合并到这个分支，
> 
> 于是xiyoumi小朋友重新提交了pull request，要求把合并到test分支里，
> 
> ade愉快的合并了这个pull request，并且不久后把这个分支也合并进了主干(master分支)。

* * *

### 剧情详情

好吧，具体来看看这个故事的每一段都做了点啥

#### ade心血来潮新建了个github的repo(仓库)，

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/createRepo.png)

#### 然后在repo里乱七八糟的写了点东西后提交(commit)进repo，

```
[ade@~]$git init story
Initialized empty Git repository in /home/ade/story/.git/
[ade@~]$cd story
[ade@story]$git remote add origin git@github.com:edxi/story.git
[ade@story]$echo "this is a story repository" >> README.md
[ade@story]$git add -A
[ade@story]$git commit -m "first commit"
[master (root-commit) 5a98272] first commit
 1 file changed, 1 insertion(+)
 create mode 100644 README.md
[ade@story]$git push -u origin master
Counting objects: 3, done.
Writing objects: 100% (3/3), 225 bytes | 0 bytes/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To git@github.com:edxi/story.git
 * [new branch]      master -> master
Branch master set up to track remote branch master from origin.
```

#### 好奇的xiyoumi小朋友发现了这个repo，于是把repo在自己的github上做了个副本(fork)，

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/fork.png)

#### xiyoumi小朋友把里面的东西做了点修改，也做了自己的提交，

```
[xiyoumi@~]$git clone git@github.com:xiyoumi/story.git
Cloning into 'story'...
remote: Counting objects: 3, done.
remote: Total 3 (delta 0), reused 3 (delta 0), pack-reused 0
Receiving objects: 100% (3/3), done.
[xiyoumi@~]$cd story/
[xiyoumi@story]$echo "三只小猪的故事" >> pigstory.md
[xiyoumi@story]$echo "xiyoumi参与写作！" >> README.md
[xiyoumi@story]$git commit -m "交作文！"
[master 13d8cc2] 交作文！
 2 files changed, 2 insertions(+)
 create mode 100644 pigstory.md
[xiyoumi@story]$git push
warning: push.default is unset; its implicit value is changing in
Git 2.0 from 'matching' to 'simple'. To squelch this message
and maintain the current behavior after the default changes, use:

  git config --global push.default matching

To squelch this message and adopt the new behavior now, use:

  git config --global push.default simple

See 'git help config' and search for 'push.default' for further information.
(the 'simple' mode was introduced in Git 1.7.11. Use the similar mode
'current' instead of 'simple' if you sometimes use older versions of Git)

Counting objects: 6, done.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (4/4), 372 bytes | 0 bytes/s, done.
Total 4 (delta 0), reused 0 (delta 0)
To git@github.com:xiyoumi/story.git
   5a98272..13d8cc2  master -> master
```

#### xiyoumi小朋友想把自己改的东西也合并到ade的repo里，于是提交了pull request，

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/pullrequest.png)

#### ade看了下pull request，觉得修改的不错，于是就合并进了repo，

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/mergepullrequest.png)

#### xiyoumi小朋友大受鼓舞，又修改了好多东西，并再次提交pull request，

```
[xiyoumi@story]$echo "三只小猪最终打败了大灰狼" >> pigstory.md
[xiyoumi@story]$git add -A
[xiyoumi@story]$git commit -m "故事有更新啦！"
[master 60ab6ec] 故事有更新啦！
 1 file changed, 1 insertion(+)
[xiyoumi@story]$git push
warning: push.default is unset; its implicit value is changing in
Git 2.0 from 'matching' to 'simple'. To squelch this message
and maintain the current behavior after the default changes, use:

  git config --global push.default matching

To squelch this message and adopt the new behavior now, use:

  git config --global push.default simple

See 'git help config' and search for 'push.default' for further information.
(the 'simple' mode was introduced in Git 1.7.11. Use the similar mode
'current' instead of 'simple' if you sometimes use older versions of Git)

Counting objects: 5, done.
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 354 bytes | 0 bytes/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To git@github.com:xiyoumi/story.git
   13d8cc2..60ab6ec  master -> master
```

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/pullrequest2.png)

#### ade看到这次的pull request，也不知道这样改好不好，于是ade索性新建了个test分支(branch)，并在pull request里留言告诉xiyoumi，让他合并到这个分支里

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/closeandcomment.png)

```
[ade@story]$git push origin test
Counting objects: 3, done.
Writing objects: 100% (3/3), 225 bytes | 0 bytes/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To git@github.com:edxi/story.git
 * [new branch]      test -> test
```

#### 于是xiyoumi小朋友重新提交了pull request，要求把合并到test分支里，

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/pullrequest3.png)

#### ade愉快的合并了这个pull request，并且不久后把这个分支也合并进了主干(master分支)。

![](http://poqwdbkil.bkt.clouddn.com/static/images/ade_xiyoumi_write_story_github_example/mergetotest.png)

```
[ade@story]$git branch
  master
* test
[ade@story]$git pull origin test
From github.com:edxi/story
 * branch            test       -> FETCH_HEAD
Updating 5a98272..62fe9ef
Fast-forward
 README.md   | 1 +
 pigstory.md | 2 ++
 2 files changed, 3 insertions(+)
 create mode 100644 pigstory.md
[ade@story]$git checkout master
Switched to branch 'master'
Your branch is behind 'origin/master' by 2 commits, and can be fast-forwarded.
  (use "git pull" to update your local branch)
[ade@story]$git pull --all
Fetching origin
Updating 5a98272..31e542b
Fast-forward
 README.md   | 1 +
 pigstory.md | 1 +
 2 files changed, 2 insertions(+)
 create mode 100644 pigstory.md
[ade@story]$git merge test -m "Merge branch 'test'"
Merge made by the 'recursive' strategy.
 pigstory.md | 1 +
 1 file changed, 1 insertion(+)
[ade@story]$git push
warning: push.default is unset; its implicit value is changing in
Git 2.0 from 'matching' to 'simple'. To squelch this message
and maintain the current behavior after the default changes, use:

  git config --global push.default matching

To squelch this message and adopt the new behavior now, use:

  git config --global push.default simple

See 'git help config' and search for 'push.default' for further information.
(the 'simple' mode was introduced in Git 1.7.11. Use the similar mode
'current' instead of 'simple' if you sometimes use older versions of Git)

Counting objects: 1, done.
Writing objects: 100% (1/1), 210 bytes | 0 bytes/s, done.
Total 1 (delta 0), reused 0 (delta 0)
To git@github.com:edxi/story.git
   31e542b..4804dda  master -> master
```

* * *

### 尾声

到这里，已经知道了ade和xiyoumi是怎么通过github一起写故事了，可是似乎还没有这么简单，不久之后他们又有了新的问题：

*   xiyoumi发现fork源的repo早就变了，怎么同步呢？
*   随着越来越多的人加入故事投稿，分支和提交觉得乱糟糟的，怎么才能简洁点呢？能不能删除git log呢？

问题的答案至今还不知晓~

> 一个人走得快，一群人走得远
> 
> ——《有赞》广告词
