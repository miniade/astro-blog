---
author: edxi
pubDatetime: "2018-03-18T18:18:18Z"
title: ChatOps! 自制Poshbot插件管理VMware
slug: PoshBotVMware
featured: false
draft: false
tags:
  - PowerShell
  - Slack
  - ChatOps
  - VMware
description: 这些词你有听说过嘛？  DevOps ChatOps AIOps NoOps  OOooooopps…这里写的内容是ChatOps…就像过完年这段时间特别的忙，手机上几十个聊天群，这时候ChatOps这个词浮现再眼前~本质上讲，ChatOps其实意思就是聊天群里来了个机器人，这家伙会截取特定聊天内容，执行对应的动作，比方说吧：  ”看看Ben的账号是不是锁了
canonicalURL: "https://edxi.github.io/2018/03/18/PoshBotVMware/"
---

这些词你有听说过嘛？

*   DevOps
*   ChatOps
*   AIOps
*   NoOps

OOooooopps…  
这里写的内容是ChatOps…  
就像过完年这段时间特别的忙，手机上几十个聊天群，这时候ChatOps这个词浮现再眼前~  
本质上讲，ChatOps其实意思就是聊天群里来了个机器人，这家伙会截取特定聊天内容，执行对应的动作，比方说吧：

*   ”看看Ben的账号是不是锁了“
*   ”虚拟机vm1创建个快照，让Jacky审批下“
*   “每天早上9点发个数据库报表”
*   ”开个P2的ticket”

上面这些，对于聊天群里的机器人bot就是指令command，至于我们人类嘛，就发号施令就行啦！（当然，实际上也就是摆脱了这些琐事，从而把更多精力放在开发这些指令上）

这里我写了个Poshbot的插件，插件的功能是管理VMware，算是一个ChatOps的实践。插件的演示视频如下：

### PoshBot

这应该不算是一个主流的ChatOps软件，我也是之前在研究DSC的时候碰巧看到的，无论如何，对我等凡人而言，这也是大神作品了，这里贡上Github的链接[\[1\]](#fn:1)。

这个项目使用的是PowerShell，所以使用这个项目来实现ChatOps对我而言，很好的提供了管理VMware的办法，相应的插件直接写PowerCLI就行。

PoshBot的安装使用方法可以直接参考项目的README，里面包含了文档网站和大神的介绍视频，另外这里还有另外一个参与contribute的大神的Blog[\[2\]](#fn:2)，我上面的视频里面没有介绍PoshBot的安装使用方法，在这里就简要列一下：

*   首先在Slack上创建一个workspace，并在这个workspace上创建一个bot，记录下token和机器人的名字，另外还得至少有个人做bot的管理员，记录下这个slack用户名。
*   Install-Module安装PoshBot，如果报错说Module里须要export的function已经使用，安装时加上-AllowClobber参数。
*   创建一份对应刚才这个bot的配置文件，并以这份配置文件为参数启动Poshbot。
    
    ```
    $backendConfig = @{Name = 'SlackBackend'; Token = '<SLACK-API-TOKEN>'; BotAdmins = @('<SLACK-CHAT-HANDLE>')}
    $backend = New-PoshBotSlackBackend -Configuration $backendConfig
    ```
    
*   接下来就可以在slack里使用了
    
    *   首先把bot邀请到须要使用的channel里
    *   然后管理员用户直接输入poshbot命令!About查看bot状态，这种感叹号作为前置的命令，就是Poshbot命令
    *   其他的内置bot命令可以使用!help查看

好了，至此bot已经上线并可以正常和人交互了。

* * *

### Plugin

安装并启动了Poshbot后，只是加载了内置的功能，而我们真正想使用bot来实现ChatOps，就需要编写对应的Plugin。  
插件其实就是Powershell的Module，所以其实调用起来非常方便，简单讲就下面3步：

*   编写Module，并且推荐使用命名为Poshbot.ModuleName
*   把Module放在Poshbot配置文件指定的Plugin目录，或者就是Powershell的模块目录，所以，plugin的模块是可以和其他module一样放在powershell gallery上。甚至内置的命令的find-plugin/install-plugin都是可以直接连接powershell gallery来获取插件模块的
*   如果是手动复制或者Install-Module的方式安装的插件模块，那么还需要再在slack里使用!install-plugin来安装一次，使得poshbot更新相应的plugin配置文件。

至此plugin就安装完成并可以使用了，同样，也是用!help等命令了解这个plugin。

作为实践测试，我自己编写了个管理VMware的plugin[\[3\]](#fn:3)，大致思路如下：

*   首先，bot得放在一个同时可以访问slack网站和访问的VIServer(vcenter/esxi)的机器上
*   然后plugin须要存储VIServer及其对应的credential的办法，这样每次执行命令时都能自动连接这些VIServer，这个用了这些方法实现：
    *   VIServer的存储通过poshbot配置文件设置一个自定义的目录
    *   目录里存放以VIServer名和登陆用名组成的xml文件
    *   文件内存放加密后的登陆密码
    *   目录下一层创建DisabledVIServer目录，不需要连接的服务器可以暂时disable
    *   所有对VI Server增删改和加密解密都使用私有函数，这样确保没法通过bot command调用，只有配置bot服务器的人才能通过脚本调用
    *   最终，通过脚本调用私有函数实现 New/Remove/Enable/Disable VI Server
*   最后plugin自身功能就是调用poshbot的plugin配置的VIServer目录，连接服务器来实现相应的功能command

具体实现须要用到几个poshbot相关的技术：

*   plugin配置[\[4\]](#fn:4)——由于VIServer列表的存放路径写在poshbot配置中，通过在模块函数中添加如下PoshBot.FromConfig这个attribute
    
    ```
    [cmdletbinding()]
    param(
        [PoshBot.FromConfig('VIServerConfigStore')]
        [parameter(Mandatory = $true)]
        [string]$VIServerConfigStore,
    )
    ```
    
*   作为powershell module，作为command的函数除了自身的函数命名，还使用了下面这种attribute命名Poshbot command
    
    ```
    [PoshBot.BotCommand(CommandName = 'getsnapshot', Permissions = 'snapshot')]
    ```
    
*   最后，必须留意的是PoshBot最好不要直接拿对象Write-Output，尽可能转换成String输出，这里用到PoshBot的New-PoshBotCardResponse
    
    ```
    $r| ForEach-Object {
        New-PoshBotCardResponse -Title "VM $($_.vm) snapshot:" -Text ($_ | Format-List -Property vm, name | Out-String)
    }
    ```
    

另外，这里关于如何创建bot和加密VIServer的密码就不再赘述了，具体可以参考slack的网站和查看我的代码。

* * *

### 其他建议使用的功能

Poshbot其实还提供了很多其他的功能，比如

*   基于角色的访问控制RBAC
*   计划任务
*   基于聊天室事件触发的命令
*   Bot允许的Channel
*   审批

比如像我开发的这个VMware插件，像createsnapshot就可以尝试使用审批功能。

总之估计这个项目的作者肯定还会不断开发新的功能，有兴趣可以查看文档尝试使用并自行开发插件。期待更多伙伴们参与ChatOps！

* * *
