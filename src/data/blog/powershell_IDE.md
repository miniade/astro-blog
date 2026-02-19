---
author: edxi
pubDatetime: "2018-01-01T11:18:18Z"
title: PowerCLI IDE环境
slug: powershell_IDE
featured: false
draft: false
tags:
  - PowerCLI
  - VS Code
  - PowerShell ISE
description: "Happy New Year 2018 !!!奚有米先来送波祝福。  新的一年要继续好好学习，天天向上，在DevOps方面不断进步！ 工欲善其事，必先利其器 孔子（春秋）《论语·卫灵公》 为继续PowerShell方面的工作，这里整理起两个自己感觉非常好用的编辑器，并附上一些配置：  PowerShell ISE + ISESteroids VS Code "
canonicalURL: "https://edxi.github.io/2018/01/01/powershell_IDE/"
---

Happy New Year 2018 !!!  
奚有米先来送波祝福。

![](http://poqwdbkil.bkt.clouddn.com/static/images/powershell_IDE/newyear.jpg)

新的一年要继续好好学习，天天向上，在DevOps方面不断进步！

> 工欲善其事，必先利其器
> 
> **孔子（春秋）《论语·卫灵公》**

为继续PowerShell方面的工作，这里整理起两个自己感觉非常好用的编辑器，并附上一些配置：

*   PowerShell ISE + ISESteroids
*   VS Code + PowerShell Extension

此外，由于经常须要写VMware PowerCLI，所以这里也附上了两个编辑器加载Module的方法。

#### PowerShell ISE + ISESteroids

大致来讲相信多数写PowerShell都是从PowerShell ISE开始的，作为系统自带的PowerShell编辑器干净又好用（据说微软现在正在开发新的系统自带编辑器）。  
装上ISESteroids后，就完全是一个专业的IDE了，安装和配置也比较简单。  
安装方法可以直接参考[ISESteroids官网的在线和离线安装步骤](http://www.powertheshell.com/isesteroids2-2/download/)。  
这里提供两个配置的地方：

*   启动ISE后自动加载ISESteroids——如果启动的时候按住Ctrl键，则**不会**自动加载。
*   加载PowerCLI 6.5——启动的时候按住Alt键，才会自动加载。

两个配置我都是使用[PowerShell ISE Profile](https://docs.microsoft.com/en-us/powershell/scripting/core-powershell/ise/how-to-use-profiles-in-windows-powershell-ise?view=powershell-5.1)，配置如下：  

```
Add-Type -AssemblyName PresentationCore
if ([System.Windows.Input.Keyboard]::IsKeyDown('Ctrl') -eq $false)
{
  Start-Steroids
}
if ([System.Windows.Input.Keyboard]::IsKeyDown('Alt') -eq $true)
{
  if (Get-Module -ListAvailable|Where-Object{$_.name -eq "VMware.VimAutomation.Core"})
  {
    Get-Module -ListAvailable VMware* | Import-Module
  }
}
```

* * *

#### VS Code + PowerShell Extension

还记得刚学编程那会儿，Visual Studio 6.0那一大堆的CD，真是壮观~  
如今这个轻量却又功能强大的VS Code，用上手后非常喜欢！  
VS Code安装PowerShell Extension非常简单，直接在Extension里搜索PowerShell安装即可。  
配置上我参考了大神[VSC for PowerCLI](http://www.lucd.info/2016/04/23/visual-studio-code-powercli/)的博客。实现如下配置功能：

*   加载PowerCLI 6.5——启动的时候按住Alt键，才会自动加载。
*   Snippets——这里须要注意符号转义，比如下面的配置文件里使用**\\符号**把PowerShell变量的**$符号**转义，但由于**\\符号**本身再JSON里仍须要转义，所以最终powershell.json配置如下：
    
    ```
    {
      "GestStat": {
          "prefix": "PCLIStatVM",
          "body": [
              "\\$finish = (Get-Date)",
              "\\$start = \\$finish.AddDays(-1)",
              "\\$stat = 'cpu.usage.average'",
              "\\$entities = Get-VM",
              "",
              "\\$stats = Get-Stat -Entity \\$entities -Stat \\$stat -Start \\$start -Finish \\$finish",
              "# \\$stats | Group-Object -Property EntityId"
          ],
          "description": "Sample VM statistics report"
      }
    }
    ```
    
*   PowerShell Editor Services——自定义F1的PowerShell additional command。
    

配置实现使用VS Code PowerShell profile，确保VS Code的Preference-Setting (settings.json)里powershell.enableProfileLoading为默认的true。然后创建Microsoft.VSCode\_profile.ps1或profile.ps1添加配置。我直接复制了[大神的配置](http://www.lucd.info/download/Microsoft.VSCode_profile.ps1)，由于不使用脚本里那么多种类的PowerCLI版本，直接修改成加载PowerCLI6.5模块。（原脚本是发现PowerCLI在注册表里的键值来确定版本，然而6.5已经不使用该键值，甚至新版本已经直接放在PowerShell Garllery上，所以不能再用原脚本的方式加载了）

```
Add-Type -AssemblyName PresentationCore
if ([System.Windows.Input.Keyboard]::IsKeyDown('Alt') -eq $true)
{
  if (Get-Module -ListAvailable|Where-Object{$_.name -eq "VMware.VimAutomation.Core"})
  {
    Get-Module -ListAvailable VMware* | Import-Module
  }
}

$pclihelp = {
$browser = 'chrome.exe'
$pclisites = 'https://communities.vmware.com/community/vmtn/automationtools/powercli/content?filterID=contentstatus[published]~objecttype~objecttype[thread]',
'https://code.vmware.com/doc/preview?id=5975',
'https://code.vmware.com/apis/196/vsphere',
'http://blogs.vmware.com/PowerCLI',
'http://lucd.info'
Start-Process $browser $pclisites
}

Register-EditorCommand  `
-SuppressOutput `
-Name 'PowerCLI.HelpSites' `
-DisplayName 'PowerCLI Help Sites' `
-ScriptBlock $pclihelp

$pclicmdhelp = {
param([Parameter(Mandatory=$true)][Microsoft.PowerShell.EditorServices.Extensions.EditorContext]$context)
$cmdlet = $context.CurrentFile.GetText($context.SelectedRange)
$browser = 'chrome.exe'
$cmdhelp = "https://code.vmware.com/doc/preview?id=5975#/doc/$($cmdlet).html"  
Start-Process $browser $cmdhelp  
}

Register-EditorCommand `
-SuppressOutput `
-Name 'PowerCLI.HelpCmdlet' `
-DisplayName 'PowerCLI Cmdlet Help' `
-ScriptBlock $pclicmdhelp

$pscountcmdlet = {
  param([Parameter(Mandatory=$true)][Microsoft.PowerShell.EditorServices.Extensions.EditorContext]$context)  
  
  $cmdArr = @()
  $varArr = @()
  foreach($token in $context.CurrentFile.Tokens){
    switch($token.GetType().Name){
      'StringLiteralToken'{
        if($token.TokenFlags -eq 'CommandName'){
          $cmdArr += $token.Value
        }
      }
      'VariableToken'{
        $varArr += $token.Name
      }
    }
  }
  $cmdArr = $cmdArr | Sort-Object -Unique
  $varArr = $varArr | Sort-Object -Unique
  Write-Output "You used $($cmdArr.Count) different cmdlets"
  Write-Output "`t$($cmdArr -join '|')"
  Write-Output "You used $($varArr.Count) different variables"
  Write-Output "`t$($varArr -join '|')"
}


Register-EditorCommand `
-Name 'PowerShell.CountCmdletVar' `
-DisplayName 'Count Cmdlets/Variables' `
-ScriptBlock $pscountcmdlet
```

* * *

另外，VS Code实在很多可玩的地方，可以直接用在MACOS上提升逼格，可以直接Git（也可以用VSTS extension，须要visual studio的TS.exe），好多extension~ 比如映射VIM等其他编辑器的键盘设置，md语法检查，好多好多~  
好吧，Happy Coding 2018 <(￣︶￣)↗\[GO!\]y
