---
author: edxi
pubDatetime: "2017-12-21T12:25:00Z"
title: PowerCLI实现自动部署VM
slug: powercli_vmdeploy
featured: false
draft: false
tags:
  - PowerShell
  - PowerCLI
description: 最近沉迷于一项工作任务——PowerCLI实现自动部署VM，参考了大神的作品，按照实际工作环境做了修改。足足600行代码，实在繁琐，所以这里就不贴代码了，直接扔在Gist上了。现在的心情如图。通过这个脚本，顺便捡起了10年前学的powershell，这里借着这个脚本的实现总结下几个脚本里用到的技巧。
canonicalURL: "https://edxi.github.io/2017/12/21/powercli_vmdeploy/"
---

最近沉迷于一项工作任务——PowerCLI实现自动部署VM，参考了大神的[作品](http://vmwaremine.com/2014/08/25/ultimate-vm-batch-deployment-script/#sthash.oJPuxCZX.dpbs)，按照实际工作环境做了修改。足足600行代码，实在繁琐，所以这里就不贴代码了，直接扔在[Gist上了](https://gist.github.com/edxi/f80e6e4f9bffa55162ab84d2ce6b10dc)。现在的心情如图。  
![](http://poqwdbkil.bkt.clouddn.com/static/images/powercli_vmdeploy/codingyibasuo.jpg)  
通过这个脚本，顺便捡起了10年前学的powershell，这里借着这个脚本的实现总结下几个脚本里用到的技巧。  

#### 脚本功能概述

脚本大致完成下面几件事情：

1.  读取csv文件——[csv文件例子](https://gist.github.com/edxi/f80e6e4f9bffa55162ab84d2ce6b10dc)也放在Gist上了。里面带数字的列是可以增加的，比如例子只有disk1,disk2，可以继续加上disk3,disk4,disk5等等（如果新VM须要更多硬盘的话）
2.  VM部署——会根据csv文件列出的每一个VM开启一个powershell job进行部署
3.  VM创建包括下面这些后续任务：
    *   Customize——检查customize状态
    *   VM Tools升级——如果是windows则自动完成vmtools升级
    *   硬件配置——根据csv要求的硬件配置VM
    *   GuestOS脚本——执行guestOS脚本（我里面写了windows guest os的设置IP和加域的脚本，理论上应该可以添加任意想在vm里运行的任务）
4.  产生日志——包括两个层面的日志：
    *   跟踪Job状态——脚本定时检查VM部署Job的状态，并输出日志
    *   VM部署日志——各个VM部署Job产生当前部署任务的进度  
        总之，完成的任务很大程度是基于工作环境须要的，所以下面主要还是看看脚本里值得笔记的几个powershell使用技巧吧。

* * *

#### ScriptBlock

脚本里所有实际部署操作都是通关过start-job调用scriptblock完成的，所以脚本大部分（103-491行）就是定义了个scriptblock，然后里面还罪恶的嵌套了几个scriptblock，比较厉害的就是那个$continue（228-238行），返回一个bool值放在while条件里，把复杂的判断条件封装了起来。  
scriptblock定义的语法如下：  

```
$example_scriptblock={
  $a="hello"
  $b="world"
  return "$a $b!"
}
Write-Host $example_scriptblock #this will output above block definition
Write-Host (& $example_scriptblock) #this will output "hello world!"
```

上面使用&符号执行scriptblock，像start-job这类命令直接调用ScriptBlock变量即可。

另外，scriptblock也是可以加参数的。用法与函数和脚本自身的参数定义

* * *

#### 通过hash跟踪任务

hash真的越用越好用，脚本里多处使用：

*   start-job放进一个hash里，用来跟踪Job状态
*   新建VM放进hash里，跟踪vm创建状态
*   升级vmtools任务放进hash，跟踪升级成功状态
*   配置硬件的任务放进hash里，跟踪硬件配置是否成功

hash一般定义和使用这里就不赘述了，这里写个例子用来把vmhost放进hash  

```
$hosthash=@{}
get-vmhost|%{$hosthash[$_.name]=$_.NumCpu}
```

这里还用到了%{}符号，其实就是把管道前输出的做foreach，通过这个方法把hash内容赋值。

一般来讲，获取value比较方便，这里有个方法通过value来获取key的  

```
($hosthash.GetEnumerator()|where{$_.value -eq 24}).name
```

* * *

#### 自定义对象

脚本里用了两种方式自定义对象。  
第一种规规矩矩的用New-Object PSObject和Add-Member创建。  

```
$job_progress = New-Object PSObject
$job_progress | Add-Member -Name "PWROK" -Value 0 -MemberType NoteProperty
```

第二种通过管道  

```
$obj = "" | select VM,CustomizationStatus,StartVMEvent
```

总体来说，都比较灵活，后期使用还是要当心点，切记“动态类型一时爽，代码重构火葬场”。

* * *

#### 其他总结

*   System.Collections.ArrayList和@()符号定义的list还是有不同的，脚本里的220行和226行用到
*   Job通过一个自定义变量产生的csv来跟踪状态，并拿到对应值可以用write-progress画进度条（610-647行）
*   用\[Diagnostics.Stopwatch\]::StartNew()监控总体任务耗时（572,659,660行）
*   脚本执行不下去的话可以用get-job看job状态，receive-job获得job交互信息（比如执行guest os script时如果须要输入guest os用户名密码，那么就会须要弹出对话框交互）
*   Invoke-VMScript命令传送的**不是**花括号定义的scriptblock，而是单引号定义的字符串，具体定义规则参考[vmware technote](https://www.vmware.com/content/dam/digitalmarketing/vmware/en/pdf/techpaper/vsphere_power-cli-5.1-r1_technote.pdf)，前提条件不少，也建议参考[大牛博客](http://www.lucd.info/2012/01/01/will-invoke-vmscript-work/)写的使用方法

* * *

另外，本来还打算继续写基于vcenter的vm部署脚本。（大神原作是基于cluster的，而且会按照cluster内host数量均衡的部署）  
好吧，总之现在先打算弃坑了，又接到新的任务了 <(￣︶￣)↗\[GO!\]
