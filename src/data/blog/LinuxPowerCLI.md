---
author: edxi
pubDatetime: "2018-03-30T15:19:18Z"
title: 在Linux和Docker上使用PowerCLI
slug: LinuxPowerCLI
featured: false
draft: false
tags:
  - PowerCLI
  - Docker
description: 奚有米一岁啦！先来张庆生照！ 时间过的真快，VMware也已经10周年了，PowerCLI也在上个月发布了新的版本，版本号也直接从6.5到了10[1]，就是为了10周年的缘故吧，在slack的讨论里也有这样的解释：  Because 7 8(ate) 9  随着这次的版本的更新，更是加入了对MacOS和多种Linux发行版本的支持，这个月其Docker版本也
canonicalURL: "https://edxi.github.io/2018/03/30/LinuxPowerCLI/"
---

奚有米一岁啦！先来张庆生照！  
![](http://poqwdbkil.bkt.clouddn.com/static/images/LinuxPowerCLI/1year.jpg)

时间过的真快，VMware也已经10周年了，PowerCLI也在上个月发布了新的版本，版本号也直接从6.5到了10[\[1\]](#fn:1)，就是为了10周年的缘故吧，在slack的讨论里也有这样的解释：

> Because 7 8(ate) 9

随着这次的版本的更新，更是加入了对MacOS和多种Linux发行版本的支持，这个月其Docker版本也有了更新。所以这篇博客记录下几种不同环境下PowerCLI的安装方法。

### Linux安装PowerCLI

目前官方已经支持在MacOS和好几种Linux发行版上使用PowerCLI，这里测试的机器是CentOS7。

实际上，正是因为现在.net core和PowerShell已经支持了在多种操作系统上运行，所以使得PowerCLI作为一个PowerShell模块可以运行在Linux和MacOS。

安装步骤也比较简单：

*   安装PowerShell
    
    ```
    [root@host1 ~]# curl https://packages.microsoft.com/config/rhel/7/prod.repo | sudo tee /etc/yum.repos.d/microsoft.repo
    [root@host1 ~]# yum install powershell
    ```
    
*   安装PowerCLI模块
    
    ```
    [root@host1 ~]# pwsh
    PowerShell v6.1.0-preview.1
    Copyright (c) Microsoft Corporation. All rights reserved.
    
    https://aka.ms/pscore6-docs
    Type 'help' to get help.
    
    PS /root> install-module vmware.powercli -Scope CurrentUser
    ```
    

安装完成的powercli module目录会在 ~/.local/share/powershell/Modules/  
接下来就可以直接使用PowerCLI命令了。

MacOS环境下的安装这里就省略了，具体步骤可以参考官方博客[\[2\]](#fn:2)

* * *

### 通过Docker使用PowerCLI

我这里使用PhotonOS v2测试了Docker下使用PowerCLI，安装使用也非常简单：

*   下载PowerCLI Image
    
    ```
    root@PhotonOS2 [ ~ ]# docker pull vmware/powerclicore
    Using default tag: latest
    latest: Pulling from vmware/powerclicore
    e9b1ffebdf09: Pull complete
    1ca0671214e4: Pull complete
    e2054d0e7b6e: Downloading [=================>                                 ]  29.73MB/83.88MB
    9e5896375981: Download complete
    e2054d0e7b6e: Downloading [===============================>                   ]  52.98MB/83.88MB
    e2054d0e7b6e: Downloading [====================================>              ]  12.85MB/17.76MB
    e2054d0e7b6e: Pull complete
    9e5896375981: Pull complete
    4fda4ed0aa8e: Pull complete
    ae595f021807: Pull complete
    2223c2963494: Pull complete
    c0625c88535b: Pull complete
    Digest: sha256:4c19d7f6e5b460cdcea403977f1e8491f5c28c81a60e84dddf9d65921ba3ac51
    Status: Downloaded newer image for vmware/powerclicore:latest
    ```
    
*   运行PowerCLI container
    
    ```
    root@PhotonOS2 [ ~ ]# docker run -it vmware/powerclicore
    PowerShell v6.0.1
    Copyright (c) Microsoft Corporation. All rights reserved.
    
    https://aka.ms/pscore6-docs
    Type 'help' to get help.
    
    PS /root> $PSVersionTable
    
    Name                           Value
    ----                           -----
    PSVersion                      6.0.1
    PSEdition                      Core
    GitCommitId                    v6.0.1
    OS                             Linux 4.9.80-1.ph2-esx #1-photon SMP Wed Feb 14 14:45:42 UTC 2018
    Platform                       Unix
    PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
    PSRemotingProtocolVersion      2.3
    SerializationVersion           1.1.0.1
    WSManStackVersion              3.0
    ```
    

* * *

> 时间就是知识，时间就是力量，时间就是生命。——郭沫若
