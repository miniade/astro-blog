---
author: edxi
pubDatetime: "2018-02-27T08:19:08Z"
title: 使用DSCEA和BaselineManagement做合规检查
slug: WinBaseline
featured: false
draft: false
tags:
  - PowerShell
  - DSC
  - Group Policy
description: 这里所说的合规检查指的是Windows Baseline Compliance Check。 原本微软有个SCM的安全检查工具[1]，可以做合规检查的工作，但是目前这个工具已经退役了，并因此推荐了这篇博客所提及的两个开源工具DSCEA和BaselineManagement[2]，另外还有SCT这个工具[3]，总之，关于安全合规，可以参考微软官方文档[4]了解
canonicalURL: "https://edxi.github.io/2018/02/27/WinBaseline/"
---

这里所说的合规检查指的是Windows Baseline Compliance Check。

原本微软有个SCM的安全检查工具[\[1\]](#fn:1)，可以做合规检查的工作，但是目前这个工具已经退役了，并因此推荐了这篇博客所提及的两个开源工具DSCEA和BaselineManagement[\[2\]](#fn:2)，另外还有SCT这个工具[\[3\]](#fn:3)，总之，关于安全合规，可以参考微软官方文档[\[4\]](#fn:4)了解更多。

当然，合规也未必只限于安全方面，说到底，只要系统和自己定义的配置相符，那么就可以认为是合规。 这里用“有米饺”举个例子，嘿嘿(●ˇ∀ˇ●)

![](http://poqwdbkil.bkt.clouddn.com/static/images/WinBaseline/youmijiao.jpg)

所以，DSCEA内部使用Test-DscConfiguration，很好的做到了检查相应的配置，而不局限于安全方面。

由于BaselineManagement和DSCEA作为开源的PowerShell程序，目前官方的文档还比较少，很多还是依赖于社区资源，所以这里记录下使用方法。

### BaselineManagement

这个项目的官方README介绍[\[5\]](#fn:5)模块作用是把SCM的XML/JSON或者GPO直接转换成DSC的MOF文件，省下了自己手动写DSC配置脚本的大量工作。目前我只使用了转换GPO的功能，大致步骤如下：

*   准备好GPO文件/目录——通常，要看所需GPO的具体设置，GPO可能会包含几种文件，可以通过GPM或LGPO这类工具备份/导出。
*   在执行转换的机器上安装BaselineManagement模块，包括如下：
    *   首先，当然是至少须要是PowerShell 5。
    *   Install-Module BaselineManagement安装模块，测试下来必须安装在AllUsers的Scope下，否则模块执行会报错。
    *   可选的，安装如下模块：
        *   Carbon, xSmbShare, DSCR\_PowerPlan, xScheduledTask，这几个模块可以通过PSGallery直接安装。
        *   rsInternationalSettings, PrinterManagement，这两个模块没有上传到PSGallery只能通过github下载手动复制到$env:PSModulePath目录。
*   执行转换命令ConvertFrom-GPO -Path PathToGPO，生成mof文件。

* * *

### DSCEA

有了上面BaselineManagement生成的DSC .mof文件，接下来就可以使用DSCEA来扫描机器是否符合相应的DSC配置。  
实际上对于DSCEA而言，其本身从哪里拿的DSC配置文件并不重要，所以这里也就不限定于刚才的SCM或GPO这些与安全合规关系比较大的配置了。DSCEA他起的作用只是扫描机器并产生报表。DSCEA有比较完善的文档[\[6\]](#fn:6)，其中有几个自己生成DSC配置的Sample，这里就不再详细写使用方法了，下面直接把结合两个工具的整个使用过程录制了下来。

![](http://poqwdbkil.bkt.clouddn.com/static/images/WinBaseline/BaselineCheck.gif)

* * *
