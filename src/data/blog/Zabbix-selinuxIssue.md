---
author: edxi
pubDatetime: "2017-11-08T20:11:00Z"
title: Zabbix学习笔记--CentOS7安装selinux修改（转）
slug: Zabbix-selinuxIssue
featured: false
draft: false
tags:
  - Zabbix
description: 在CentOS 7安装Zabbix 3.4后，SELINUX开启，启动Zabbix-Server报错。经查为Zabbix 3.4已知故障[1]记录故障现象及解决方法（参考Baleam的博客[2]）
canonicalURL: "https://edxi.github.io/2017/11/08/Zabbix-selinuxIssue/"
---

在CentOS 7安装Zabbix 3.4后，SELINUX开启，启动Zabbix-Server报错。  
经查为Zabbix 3.4已知故障[\[1\]](#fn:1)  
记录故障现象及解决方法（参考Baleam的博客[\[2\]](#fn:2)）

#### 故障现象

systemd报错如下：  

```
[root@ansible02 ~]# systemctl status zabbix-server.service
● zabbix-server.service - Zabbix Server
   Loaded: loaded (/usr/lib/systemd/system/zabbix-server.service; enabled; vendor preset: disabled)
   Active: activating (auto-restart) (Result: exit-code) since Wed 2017-11-08 19:57:09 CST; 6s ago
  Process: 24278 ExecStop=/bin/kill -SIGTERM $MAINPID (code=exited, status=1/FAILURE)
  Process: 24227 ExecStart=/usr/sbin/zabbix_server -c $CONFFILE (code=exited, status=0/SUCCESS)
 Main PID: 24229 (code=exited, status=0/SUCCESS)

Nov 08 19:57:09 ansible02.mylab.com systemd[1]: zabbix-server.service: control process exited, code=exited status=1
Nov 08 19:57:09 ansible02.mylab.com systemd[1]: Unit zabbix-server.service entered failed state.
Nov 08 19:57:09 ansible02.mylab.com systemd[1]: zabbix-server.service failed.
```

开启/etc/zabbix/zabbix\_server.conf  

```
LogFile=/var/log/zabbix/zabbix_server.log
```

报错日志如下  

```
[root@ansible02 ~]# more /var/log/zabbix/zabbix_server.log
 22072:20171107:055224.207 Starting Zabbix Server. Zabbix 3.4.3 (revision 73588).
 22072:20171107:055224.207 ****** Enabled features ******
 22072:20171107:055224.207 SNMP monitoring:           YES
 22072:20171107:055224.207 IPMI monitoring:           YES
 22072:20171107:055224.207 Web monitoring:            YES
 22072:20171107:055224.207 VMware monitoring:         YES
 22072:20171107:055224.207 SMTP authentication:       YES
 22072:20171107:055224.207 Jabber notifications:      YES
 22072:20171107:055224.207 Ez Texting notifications:  YES
 22072:20171107:055224.207 ODBC:                      YES
 22072:20171107:055224.207 SSH2 support:              YES
 22072:20171107:055224.207 IPv6 support:              YES
 22072:20171107:055224.207 TLS support:               YES
 22072:20171107:055224.207 ******************************
 22072:20171107:055224.207 using configuration file: /etc/zabbix/zabbix_server.conf
 22072:20171107:055224.229 current database version (mandatory/optional): 03040000/03040005
 22072:20171107:055224.229 required mandatory version: 03040000
 22072:20171107:055224.262 server #0 started [main process]
 22083:20171107:055224.287 server #8 started [discoverer #1]
 22084:20171107:055224.300 server #9 started [history syncer #1]
 22080:20171107:055224.301 server #5 started [housekeeper #1]
 22077:20171107:055224.301 server #2 started [alerter #1]
 22078:20171107:055224.302 server #3 started [alerter #2]
 22079:20171107:055224.302 server #4 started [alerter #3]
 22082:20171107:055224.302 server #7 started [http poller #1]
 22086:20171107:055224.303 server #11 started [history syncer #3]
 22076:20171107:055224.303 server #1 started [configuration syncer #1]
 22081:20171107:055224.304 server #6 started [timer #1]
 22085:20171107:055224.304 server #10 started [history syncer #2]
 22087:20171107:055224.305 server #12 started [history syncer #4]
 22089:20171107:055224.305 server #14 started [proxy poller #1]
 22091:20171107:055224.310 server #16 started [task manager #1]
 22093:20171107:055224.310 server #18 started [poller #2]
 22095:20171107:055224.316 server #20 started [poller #4]
 22090:20171107:055224.319 server #15 started [self-monitoring #1]
 22092:20171107:055224.320 server #17 started [poller #1]
 22094:20171107:055224.324 server #19 started [poller #3]
 22096:20171107:055224.328 server #21 started [poller #5]
 22088:20171107:055224.331 server #13 started [escalator #1]
 22106:20171107:055224.360 server #22 started [unreachable poller #1]
 22107:20171107:055224.374 server #23 started [trapper #1]
 22111:20171107:055224.378 server #27 started [trapper #5]
 22114:20171107:055224.382 server #30 started [preprocessing manager #1]
 22114:20171107:055224.383 cannot start preprocessing service: Cannot bind socket to "/var/run/zabbix/zabbix_server_preprocessing.sock": [13] Permission denied.
 22072:20171107:055224.385 One child process died (PID:22114,exitcode/signal:1). Exiting ...
 22072:20171107:055226.387 syncing history data...
 22072:20171107:055226.387 syncing history data done
 22072:20171107:055226.387 syncing trend data...
 22072:20171107:055226.387 syncing trend data done
 22072:20171107:055226.387 Zabbix Server stopped. Zabbix 3.4.3 (revision 73588).
```

其中发现关键报错  

```
cannot start preprocessing service: Cannot bind socket to "/var/run/zabbix/zabbix_server_preprocessing.sock": [13] Permission denied.
```

#### 修复方法

通过下载并导入官方支持提供的selinux模块包可以修复  

```
# getsebool -a | grep zabbix
httpd_can_connect_zabbix --> on
zabbix_can_network --> off
# setsebool -P zabbix_can_network on

# systemctl stop mysqld
# systemctl stop zabbix-server
# systemctl stop zabbix-agent
# yum install -y policycoreutils-python
# wget -O zabbix_server_add.te https://support.zabbix.com/secure/attachment/53320/53320_zabbix_server_add.te –no-check-certificate
# checkmodule -M -m -o zabbix_server_add.mod zabbix_server_add.te
# semodule_package -o zabbix_server_add.pp -m zabbix_server_add.mod
# semodule -i zabbix_server_add.pp
# systemctl restart zabbix-server;
# systemctl restart zabbix-agent

# systemctl start mysqld
# systemctl start zabbix-server
# systemctl start zabbix-agent
```

* * *

参考
