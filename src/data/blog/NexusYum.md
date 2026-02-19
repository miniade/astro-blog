---
author: edxi
pubDatetime: "2018-04-16T08:09:18Z"
title: 使用Nexus自建Yum Repository代理
slug: NexusYum
featured: false
draft: false
tags:
  - Nexus
description: 以往为了让内网服务器使用Yum，自建了Yum服务器，大致就是一个apache指向自建的repository目录，然后使用yum-util里的reposync更新rpm（当然也可以手动下载后放到repo目录），再使用createrepo来创建metadata。虽说可以实现，但是也存在不少不便：  repo目录日趋庞大 EPEL这样的repo没法下载 同时维护c
canonicalURL: "https://edxi.github.io/2018/04/16/NexusYum/"
---

以往为了让内网服务器使用Yum，自建了Yum服务器，大致就是一个apache指向自建的repository目录，然后使用yum-util里的reposync更新rpm（当然也可以手动下载后放到repo目录），再使用createrepo来创建metadata。虽说可以实现，但是也存在不少不便：

*   repo目录日趋庞大
*   EPEL这样的repo没法下载
*   同时维护centos7和centos6这样多个版本比较麻烦
*   只能crontab定期更新，repo内容可能会滞后

最近使Sonatype Nexus的时候发现可以支持Yum Repository，官方博客也早在去年八月就发布了这个功能[\[1\]](#fn:1)，通过这个新功能，使得自建的repo可以解决这些困难着实解决了上面这些困难，这里简单介绍下Nexus服务器自建Yum Repository代理的过程。

Nexus的安装和配置过程都比较简单，当然Nexus的功能远不限于此，它提供了当下最流行的库支持（Maven/Java, npm, NuGet, RubyGems, Docker, P2, OBR, APT, YUM 等等），也支持cluster，还提供rest API和基于OSGi的bundle开发。我这里只是让它小露一手而已~  
附《绿巨人击倒奚有米》的动图，嘿嘿(o゜▽゜)o☆

![](http://poqwdbkil.bkt.clouddn.com/static/images/NexusYum/HulkPunch.gif)

### 安装Nexus

官方文档[\[2\]](#fn:2)的安装过程并不复杂，我这里简单罗列了使用CentOS7安装的步骤：  

```
# 确保安装了JRE 8
$ java -version
openjdk version "1.8.0_161"
OpenJDK Runtime Environment (build 1.8.0_161-b14)
OpenJDK 64-Bit Server VM (build 25.161-b14, mixed mode)

# 建议创建nexus用户，并设置该用户File Handle Limits
$ sudo useradd nexus
$ sudo echo "nexus - nofile 65536" >> /etc/security/limits.conf

# 下载并解压nexus到/opt目录，并设置nexus用户权限
$ wget https://download.sonatype.com/nexus/3/latest-unix.tar.gz
$ sudo tar -xzvf latest-unix.tar.gz -C /opt
$ sudo mv /opt/nexus* /opt/nexus
$ sudo chown -R nexus:nexus /opt/nexus /opt/sonatype-work/

# 设置服务启动用户
$ sudo echo 'run_as_user="nexus"' > /opt/nexus/bin/nexus.rc

# 这里使用systemd管理服务
$ sudo cat <<EOF >/etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target
  
[Service]
Type=forking
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort
  
[Install]
WantedBy=multi-user.target
EOF

$ sudo systemctl daemon-reload
$ sudo systemctl enable nexus.service
$ sudo systemctl start nexus.service

# 最后，查看log了解服务运行状态
$ tail -f /opt/sonatype-work/nexus3/log/nexus.log
```

* * *

### Docker方式运行Nexus

另一种方式是使用docker运行，可以参考官方的docker github[\[3\]](#fn:3)，列举命令如下：  

```
# 后台运行并映射8081端口，每次随主机启动
$ docker run -d -p 8081:8081 --restart=always --name nexus sonatype/nexus3

# 查看运行状态
$ docker logs -f nexus

# 传递环境变量，调整JAVA参数
$ docker run -d -p 8081:8081 --name nexus -e INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g  -Djava.util.prefs.userRoot=/some-other-dir" sonatype/nexus3

# 持久化/nexus-data目录到docker volume
$ docker volume create --name nexus-data
$ docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3

# 持久化到主机的目录（不具便携性）
$ mkdir /some/dir/nexus-data && chown -R 200 /some/dir/nexus-data
$ docker run -d -p 8081:8081 --name nexus -v /some/dir/nexus-data:/nexus-data sonatype/nexus3

# 自己通过nexus3的image为基础Build一个新的image
$ docker build --rm=true --tag=sonatype/nexus3 .
#The following optional variables can be used when building the image:
#  NEXUS_VERSION: Version of the Nexus Repository Manager
#  NEXUS_DOWNLOAD_URL: Download URL for Nexus Repository, alternative to using NEXUS_VERSION to download from Sonatype
#  NEXUS_DOWNLOAD_SHA256_HASH: Sha256 checksum for the downloaded Nexus Repository Manager archive. Required if NEXUS_VERSION or NEXUS_DOWNLOAD_URL is provided
```

* * *

### 配置Yum Repository

Yum的Repository分为proxy和host两种，两种分别用于不同的用途：

*   Host——如果是为了存放公司内部的rpm，那么创建Host类型的repository，设置定时任务更新metadata，以提供公司内部使用。一般须要做的配置的内容包括：
    
    *   Repository的名字
    *   Repodata深度，用于指定从第几层目录开始创建metadata
    *   指定Blob store，事先创建的blob store是repo库存放的目录
    *   然后就可以上传rpm了，上传的方式其实就是对repo的链接做HTTP POST，这里用crul示例
        
        ```
        curl -v --user 'admin:admin123' --upload-file ./test.rpm http://localhost:8081/repository/yum-hosted/test.rpm
        ```
        
    *   最后，使用Rebuild Yum metadata的schedule task来重建metadata
        
*   Proxy——如果目的是让客户端直接使用外网的repository，可以使用这种类型作为代理，proxy里只会存放客户端下载过的rpm。这里着重介绍这种方式。

Proxy Repository创建的方法非常简单，完全图形化，主要须要配置的也就是须要代理的公网repository，比如:

*   centos可以用[http://mirror.centos.org/centos/](http://mirror.centos.org/centos/)
*   epel用[http://mirrors.aliyun.com/epel/](http://mirrors.aliyun.com/epel/)

这里录了屏

![](http://poqwdbkil.bkt.clouddn.com/static/images/NexusYum/NexusYum.gif)

完成后就可以配置客户端使用这个repo了（在刚才配置的repo里可以看到访问链接），下面是centos和epel的repo文件示例：  

```
[root@client01 yum.repos.d]# cat nexus.repo
[nexus]
name=Nexus Repository
baseurl=http://repo.mylab.com:8081/repository/yum-proxy/$releasever/os/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
priority=1

[root@client01 yum.repos.d]# cat nexus-epel.repo
[nexus-epel-debuginfo]
name = Extra Packages for Enterprise Linux 7 - $basearch - Debug
baseurl = http://repo.mylab.com:8081/repository/yum-epel-proxy/7/$basearch/debug
failovermethod = priority
enabled = 0
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck = 0

[nexus-epel-source]
name = Extra Packages for Enterprise Linux 7 - $basearch - Source
baseurl = http://repo.mylab.com:8081/repository/yum-epel-proxy/7/SRPMS
failovermethod = priority
enabled = 0
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck = 0

[nexus-epel]
baseurl = http://repo.mylab.com:8081/repository/yum-epel-proxy/7/$basearch
failovermethod = priority
gpgcheck = 0
name = EPEL YUM repo
```

至此，客户端就可以连接自己的repo服务器下载rpm了，如果所须要的包是第一次下载，那么proxy会连接指定的外网repo下载，但如果是proxy已经存在的repo，那么直接从proxy上拉下来，速度会比外网下载快很很多！

* * *
