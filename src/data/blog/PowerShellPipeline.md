---
author: edxi
pubDatetime: "2018-01-15T21:21:21Z"
title: PowerShell 一把梭
slug: PowerShellPipeline
featured: false
draft: false
tags:
  - PowerShell
  - Release Pipeline
  - CD/CI
  - VS Code
description: 本来标题想叫《PowerShell实现模块发布流水线》的，但是这个洋气高大上的标题抄袭痕迹太严重了，好吧，不得不承认我的学习成果通常都是大量参(copy)考(paste)大神博客的。（估计写个爬虫爬一下我的博客，也会发现大神这个词出现频率肥肠高~） 先用下面这个视频解释下什么是流水线~嘿嘿，玩笑啦~(￣▽￣)~* 其实还是从字面解释吧，PowerShell模
canonicalURL: "https://edxi.github.io/2018/01/15/PowerShellPipeline/"
---

本来标题想叫《PowerShell实现模块发布流水线》的，但是这个洋气高大上的标题抄袭痕迹太严重了，好吧，不得不承认我的学习成果通常都是大量参(copy)考(paste)[大神博客](http://ramblingcookiemonster.github.io/PSDeploy-Inception/)的。（估计写个爬虫爬一下我的博客，也会发现大神这个词出现频率肥肠高~）

先用下面这个视频解释下什么是流水线~  
  
嘿嘿，玩笑啦~(￣▽￣)~\*

其实还是从字面解释吧，PowerShell模块–发布–流水线：

*   PowerShell模块——把脚本写成模块。
*   发布——把写好的模块发布给其他人用，比如上传到PowerShell Gallery。一般来说发布前要做好打包和测试。
*   流水线——写好代码提交版本后，自动完成打包–测试–发布这些动作，比如提交到GitHub后AppVeyor完成自动化流水线操作。

### 在开始之前

可能先找个例子作解释更好，所以这里把我已经提交[GitHub](https://github.com/edxi/BaselineCheck)并发布在[PSGallery](https://www.powershellgallery.com/packages/BaselineCheck/)的一个名字叫BaselineCheck的模块作为例子。  
良好的目录结构(Scaffold)是程序员自我修养的一部分，我这里大致是这个样子：  

```
D:\DOC\GITHUB\BASELINECHECK
│   .gitignore
│   appveyor.yml————AppVeyor配置文件
│   BaselineCheck.psd1————模块的manifest
│   BaselineCheck.psm1————模块本身
│   Build.ps1————VScode提供的psake脚本
│   LICENSE
│   README.md
│
├───.vscode
│       launch.json————VScode调试配置
│       tasks.json————VScode任务配置
│
├───Build————使用AppVeyor相关的一大堆脚本
│   │   build.requirements.psd1
│   │   deploy.psdeploy.ps1
│   │   psake.ps1
│   │   Start-Build.ps1
│   │
│   └───helpers
│           Install-PSDepend.ps1
│
├───Images
│       PowerShell_icon.png
│
├───Private————私有函数，不export给用户使用
│       Get-FileName.ps1
│
├───Public————公有函数，会export出来
│       Compare-Rsop.ps1
│       Compare-ScriptOutput.ps1
│       Find-RsopSetting.ps1
│       Find-XmlNodes.ps1
│
└───Tests————Pester测试脚本
        BaselineCheck.Tests.ps1
```

这个目录结构的好处是：

*   每次新建项目可以直接拷贝使用，基本上只要修改功能代码和测试脚本就行。
*   包含了VScode的手动触发的任务和AppVeyor自动流水线的脚本。

* * *

### PowerShell 模块

写成模块又很多好处，比如下面这一把梭：

*   Simplify code organization
*   Group related functions together
*   Share state between functions, but not with the user
*   Re-use “helper functions” that you don’t want exposed to the user
*   Improve discoverability: Find-Module MyModule or Get-Command -Module MyModule
*   Simplify distribution: Install-Module MyModule

具体做起来，当然看下写模块的[官方文档](https://msdn.microsoft.com/en-us/library/dd878310.aspx)是很值得的，自己总结下来也就3步：

1.  写完功能代码.ps1——可选项：建议写成函数方式，可能的话函数可以使用begin-process-end方式处理管道。
2.  写一个模块代码.psm1——可以直接把.ps1改名成.psm1，但是通常代码会包含多个.ps1，所以把代码按照scaffold组织存放.ps1，然后写一个.psm1来调用，所以这个[模块调用代码](https://github.com/edxi/BaselineCheck/blob/master/BaselineCheck.psm1)也是一劳永逸，不用修改。
3.  生成Manifest文件.psd1——可以直接拷贝官网例子（自己用New-Guid改个GUID），也可以用New-ModuleManifest命令生成，然后修改下里面的版本和导出函数等等的设置。

这样模块最基本所需要的内容就算完成了，如果还要写帮助文档、Format.ps1xml，建议继续参考[大神博客](http://ramblingcookiemonster.github.io/)吧~

* * *

### 打包-测试-发布

前面说了整个流水线的包含了打包-测试-发布这些步骤，这里逐一列出所需要使用的工具。  
其中psake/BuildHelpers/PSDepend/PSDeploy这些模块须要从PSGallery下载安装，以安装psake举例，命令如下：  

```
Install-Module psake -scope currentuser -force
```

#### psake

psake这个powershell模块用来自动化整个流程，用它提供的函数可以把各个步骤写成下面这个互相有依赖关系的任务模块：  

```
Properties {
    $someproperty = 'Define some properties for following tasks'
}

Task default -depends Build

Task Init {
    'Write init code'
}

Task Clean {
    'Write some clean code'
}

Task Build -depends Clean, Init -requiredVariables someproperty {
    'Write some build code'
}

Task Test -depends Build {
    'Write some test code, for example, invoke-pester...'
}

Task Publish -depends Test {
    'Write some publish code, for example, Invoke-PSDeploy'
}
```

VScode的task和AppVeyor都是通过调用psake来完成流程相应步骤的，接下来是完成各个发布步骤的工具了。

#### 打包

Build打包在这里没有用到什么特殊的工具，我在脚本里就做下面两件事情：

*   更新下Model Manifest
*   把模块相关的文件复制到Release目录

具体代码不再黏贴，可以直接参考Build.ps1和Build\\psake.ps1两个文件。

#### pester

pester是powershell的测试模块，现在已经集成到win10和win2016里，所以除非想要升级PSGallery上的最新版，一般也就不需要安装了。  
我们可以自己写测试脚本，写完后可以放在比如Tests目录，用Invoke-Pester来调用测试。  
每个项目的测试内容也不会相同，这里举个测试模块.psd1文件的例子：  

```
$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleManifestName = 'BaselineCheck.psd1'
Import-Module $PSScriptRoot\..\$ModuleManifestName

Describe 'Module Manifest Tests' {
    It 'Passes Test-ModuleManifest' {
        Test-ModuleManifest -Path $PSScriptRoot\..\$ModuleManifestName
        $? | Should Be $true
    }
}
```

可见测试其本身也是一个powershell脚本，只是其中调用了pester提供的函数Describe/It/Should Be等等。  
Pester的具体的语法可以参考[官方Wiki](https://github.com/Pester/Pester/wiki)。

#### 发布，PSdeploy

发布要看具体是要发布到哪里了，比如说：

*   发布到PowerShell Gallery
*   在github上生成个release
*   AppVeyor上生成个Artifacts
*   把模块目录直接复制到$PSModulePath来安装，也算是发布

总之，发布就是把做好的模块放出来，这样就可以给别人用了。  
我这里主要就是发布到PowerShell Gallery。用到的模块是PSdeploy。

PSDeploy通过Invoke-PSDeploy来调用Build目录，其中包含deploy.psdeploy.ps1文件，下面是部署到PSGallery的代码：  

```
Deploy Module {
    By PSGalleryModule {
        FromSource $ENV:PublishDir
        To PSGallery
        WithOptions @{
            ApiKey = $ENV:NugetApiKey
        }
    }
}
```

其用法看似和psake和Pester那些Alias语法很像，其中$ENV:NugetApiKey是PSGallery的API key，通过这个key来验证上传模块。  
PSDeploy可以做很多种类型的发布，具体用法也可以参考官方的[readthedocs](http://psdeploy.readthedocs.io/en/latest/)。

* * *

### 流水线

流水线就是把上面打包-测试-发布这些动作组合在一起使用，所以，可见上面这些模块里psake的重要性。然后，就是要选好调用psake的方法了，在示例的repo里，我用了VScode和AppVeyor两种方式：

*   VS Code —— 适合于本地项目，通过task完成打包、测试、发布等操作。
*   AppVeyor —— 集成GitHub或其他VSC的CI工具，直接提交代码触发相应条件来完成各个CI操作。

#### VS Code Task

在VSCode里按下F1然后输入example可以查看VS Code的示例代码，其中就有如何设置Task的方法。除了前面说到的psake，大致再复制黏贴下example的两个文件就行：

*   .vscode\\tasks.json——用来设置F1后输入task可调用的任务。
*   Build.ps1——是psake脚本，VSCode通过调用这个脚本来执行对应的任务。

这里可能须要自己手动修改这个psake脚本，比如修改不需要打包的目录和文件，是否须要使用releasenotes文件等等。  
脚本发布默认也是发布到PSGallery（怎么注册PSGallery并获取API key这里不赘述了，反正网站上点点就行），第一次发布的时候会提示输入API key，这个key会加密保存到xml文件里，以后就不必要再输入了。（可以自行调用脚本里RemoveKey任务来删除Key，其实也就是手动删xml文件）

#### AppVeyor

作为一个公网服务，先去AppVeyor注册并关联自己的GitHub Repo，接下来就是写AppVeyor配置文件和相关的Build代码。这里我也是一把梭了大神的代码（整个Build目录和appveyor.yml文件），然后按自己情况改了发布目录而已。其中各个文件的作用如下：

*   appveyor.yml——这个是必须的，我因为要发布到PSGallery，所以在AppVeyor上把PSGallery的API Key[加密](https://ci.appveyor.com/tools/encrypt)一下，放在yml文件里。
*   Start-Build.ps1——调用PSDepend检查所需要的模块，然后交给psake去处理流程各个步骤。
*   Install-PSDepend.ps1——如果PSDepend本身不存在，通过这个脚本来安装。
*   build.requirements.psd1——PSDepend列出的所需模块。
*   psake.ps1——具体流程的各个任务。这里可以包含一大堆任务，前面介绍了，具体不再赘述了。
*   deploy.psdeploy.ps1——通过psake发布任务调用，执行所需发布的类型。

总之，只要一提交GitHub，接下来会完成上面这一大堆任务了！

* * *

### 还能做些什么？

至此流水线完成，而且这样发布出来的代码结构也看上去很专业啦，哈哈。  
那么怎么再提升一点B格呢？我这里大致就是：

1.  写好README
2.  放个LICENSE
3.  RELEASE和RELEASE NOTES
4.  此外大神们厉害的项目还会有issue和wiki~

当然，关于流水线，还有很多须要学的地方，接下来自己也想学习怎么搭建Jenkins，好吧，少年~再接再厉~ o(_￣▽￣_)o
