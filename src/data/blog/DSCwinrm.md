---
author: edxi
pubDatetime: "2018-02-18T08:08:08Z"
title: DSC使用https的winrm
slug: DSCwinrm
featured: false
draft: false
tags:
  - PowerShell
  - DSC
  - winrm
description: 时至二零一八农历戊戌（狗）年春节，奚有米先来拜个年啦！   新年长假后会有一个拖延了很久的任务须要完成，于是着手研究怎么使用DSC，其中包含了winrm的配置，这篇博客简单记录下相关经验：  初始winrm。[1] 使用winrm的https方法。[2] https是否会过期。[3] 通过GPO分发winrm证书的方法。[4]
canonicalURL: "https://edxi.github.io/2018/02/18/DSCwinrm/"
---

时至二零一八农历戊戌（狗）年春节，奚有米先来拜个年啦！

![](http://poqwdbkil.bkt.clouddn.com/static/images/DSCwinrm/dogyear.jpg)

新年长假后会有一个拖延了很久的任务须要完成，于是着手研究怎么使用DSC，其中包含了winrm的配置，这篇博客简单记录下相关经验：

*   初始winrm。[\[1\]](#fn:1)
*   使用winrm的https方法。[\[2\]](#fn:2)
*   https是否会过期。[\[3\]](#fn:3)
*   通过GPO分发winrm证书的方法。[\[4\]](#fn:4)

### winrm默认配置(http 5985)

目前winrm在windows2012r2之后版本默认开启了http listener 5985端口，可以通过下面命令测试winrm连接，须要注意：

*   默认winrm服务端basic认证为false，也就是至少须要AD或证书等方式认证。
*   须要使用FQDN连接。
*   通常防火墙默认已经开启5985端口。

```
PS C:\Users\xiyoumi> Enter-PSSession -ComputerName server001.lab.com
[server001.lab.com]: PS C:\Users\xiyoumi\Documents> winrm e winrm/config/listener
Listener
    Address = *
    Transport = HTTP
    Port = 5985
    Hostname
    Enabled = true
    URLPrefix = wsman
    CertificateThumbprint
    ListeningOn = 192.168.32.12, 127.0.0.1, ::1, fe80::5efe:10.196.32.74%15, fe80::8de8:50db:9107:696a%13

[server001.lab.com]: PS C:\Users\xiyoumi\Documents> hostname
server001

[server001.lab.com]: PS C:\Users\xiyoumi\Documents> (Get-WmiObject -class Win32_OperatingSystem).Caption
Microsoft Windows Server 2012 R2 Standard
```

上面例子连接到server001.lab.com，并使用winrm命令查看listener配置。由于这是一台windows 2012 R2的服务器，所以winrm已经默认开启。  
下面命令从头开启一台服务器的winrm默认配置：

```
PS C:\Users\xiyoumi> winrm e winrm/config/listener
PS C:\Users\xiyoumi> Enable-PSRemoting

WinRM Quick Configuration
Running command "Set-WSManQuickConfig" to enable remote management of this computer by using the Windows Remote
Management (WinRM) service.
 This includes:
    1. Starting or restarting (if already started) the WinRM service
    2. Setting the WinRM service startup type to Automatic
    3. Creating a listener to accept requests on any IP address
    4. Enabling Windows Firewall inbound rule exceptions for WS-Management traffic (for http only).

Do you want to continue?
[Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):
WinRM is already set up to receive requests on this computer.
WinRM has been updated for remote management.
Created a WinRM listener on HTTP://* to accept WS-Man requests to any IP on this machine.

PS C:\Users\xiyoumi> winrm e winrm/config/listener
Listener
    Address = *
    Transport = HTTP
    Port = 5985
    Hostname
    Enabled = true
    URLPrefix = wsman
    CertificateThumbprint
    ListeningOn = 10.196.32.110, 127.0.0.1, ::1, fe80::100:7f:fffe%13
```

总的来说比较简单，一条命令解决，如果是没有加入域的机器，可以通过加-SkipNetworkProfileCheck参数，开启public zone的防火墙。  
当然也可以不用这个cmdlet，直接使用winrm命令：  

```
C:\> winrm quickconfig
WinRM is not set up to receive requests on this machine.
The following changes must be made:
 
Set the WinRM service type to delayed auto start.
 
Make these changes [y/n]? y
 
WinRM has been updated to receive requests.
 
WinRM service type changed successfully.
WinRM is not set up to allow remote access to this machine for management.
The following changes must be made:
 
Create a WinRM listener on HTTP://* to accept WS-Man requests to any IP on this machine.
Enable the WinRM firewall exception.
Configure LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
 
Make these changes [y/n]? y
 
WinRM has been updated for remote management.
 
Created a WinRM listener on HTTP://* to accept WS-Man requests to any IP on this machine.
WinRM firewall exception enabled.
Configured LocalAccountTokenFilterPolicy to grant administrative rights remotely to local users.
```

另外，关闭winrm可以使用下面步骤：

*   删除Listener
    
    ```
    winrm delete winrm/config/Listener?Address=*+Transport=HTTP
    ```
    
*   配置并停止winrm服务
    
    ```
    Set-Service -Name winrm -StartupType Disabled
    Stop-Service winrm
    ```
    
*   开启防火墙
    
    ```
    Get-NetFirewallRule | ? {$_.Displayname -eq "Windows Remote Management (HTTP-In)"} | Set-NetFirewallRule -Enabled "False"
    ```
    

上述就是一般情况的winrm使用方法，下面继续配置https的方法

* * *

### winrm配置https

首先，可以先通过默认的winrm配置测试连接已经没有问题。和http相似，https方式大致也包括下面几个配置：

*   WinRM服务正常运行
*   防火墙配置（须要手动添加5986端口）
*   添加https的Listener（须要事先生成winrm证书）

在具体开始配置之前，这里推荐一下Ansible使用的winrm配置脚本，可以直接github下载，或者从[ansible的windows文档](http://docs.ansible.com/ansible/latest/intro_windows.html#windows-system-prep)提供的链接下载[examples/scripts/ConfigureRemotingForAnsible.ps1](https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1)

这个脚本直接可以生成自签名证书，然后开启服务和防火墙，并完成listener配置。如果实在想要自己完成这些操作的话，通过下面这些命令实现：

*   开启并配置winrm服务
    
    ```
    Set-Service -Name winrm -StartupType Automatic
    Start-Service winrm
    ```
    
*   创建自签名证书。
    
    ```
    New-SelfSignedCertificate -DnsName "<YOUR_DNS_NAME>" -CertStoreLocation Cert:\LocalMachine\My
    ```
    
*   创建https winrm listener，这里的thumbprint就是刚才生成证书的thumbprint
    
    ```
    PS C:\Users\xiyoumi> Get-ChildItem -path cert:\LocalMachine\My
    
    
       PSParentPath: Microsoft.PowerShell.Security\Certificate::LocalMachine\My
    
    Thumbprint                                Subject
    ----------                                -------
    15EC9566CF4E5F3563BFE3161676E16BAAB52DD3  CN=HP840G1
    
    PS C:\Users\xiyoumi> $selectorset = @{
    	Address = "*"
    	Transport = "HTTPS"
    }
    PS C:\Users\xiyoumi> $valueset = @{
    CertificateThumbprint = "15ec9566cf4e5f3563bfe3161676e16baab52dd3"
    Hostname = "HP840G1"
    }
    PS C:\Users\xiyoumi> New-WSManInstance -ResourceURI 'winrm/config/Listener' -SelectorSet $selectorset -ValueSet $valueset
    ```
    
*   添加防火墙规则，允许5986端口访问
    
    ```
    PS C:\Users\xiyoumi> $port=5986
    PS C:\Users\xiyoumi> netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=$port
    ```
    

完成上面几部后，https的winrm就已经完成配置了，可选的我们可以删除原有的http listener：

```
winrm delete winrm/config/Listener?Address=*+Transport=HTTP
```

须要测试https连接可以使用下面命令：

```
Enter-PSSession -ComputerName HP840G1 -Port 5986 -SessionOption (New-PSSessionOption -SkipCACheck) -UseSSL
```

* * *

狗年旺起来！_(੭_ˊᵕˋ)੭\*ଘ

![](http://poqwdbkil.bkt.clouddn.com/static/images/DSCwinrm/starwardog.gif)
