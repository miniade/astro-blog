---
author: edxi
pubDatetime: "2017-10-24T10:24:00Z"
title: iTop学习笔记--安装和初始化配置
slug: iTop-initSetup
featured: false
draft: false
tags:
  - iTop
description: 大致步骤就是按照iTop官方安装文档，过程中略有小坑，这里笔记一下。
canonicalURL: "https://edxi.github.io/2017/10/24/iTop-initSetup/"
---

大致步骤就是按照[iTop官方安装文档](https://wiki.openitop.org/doku.php?id=2_3_0:install:start)，过程中略有小坑，这里笔记一下。  

#### itop相关包安装

```
yum install httpd
yum install mysql mysql-server
yum install php php-mysql php-mcrypt php-xml php-cli php-soap php-ldap graphviz php-gd
```

修改上传图片大小(/etc/php.ini和/etc/my.cnf)  
[https://wiki.openitop.org/doku.php?id=2\_3\_0:install:php\_and\_mysql\_configuration](https://wiki.openitop.org/doku.php?id=2_3_0:install:php_and_mysql_configuration)

#### 修改httpd的selinux

iTop解压到/var/www/html/itop，目录设置:

```
chown -R apache:apache /var/www/html/itop
chcon -R -t httpd_sys_rw_content_t /var/www/html/itop
```

#### 安装向导避免mysql php mismatch报错

```
yum remove php-mysql
yum install php-mysqlnd
```

#### 安装OPcache加速php

官方文档仍旧写的是遗弃项目APC，这里改用OPcache

*   [https://laravel-china.org/topics/301/using-opcache-to-enhance-the-performance-of-the-php-55-program](https://laravel-china.org/topics/301/using-opcache-to-enhance-the-performance-of-the-php-55-program)
*   [http://php.net/manual/zh/opcache.installation.php](http://php.net/manual/zh/opcache.installation.php)
    
    ```
    yum install php-pecl-zendopcache
    ```
    

检查itop配置php，删除里面不需要的翻译dictionary，以免被cache（’dictionaries’ => array里）

#### 检查mysql key cache和query cache

```
show status like 'key_reads%'; -- key_reads / key_read_requests应该小于0.1%，否则加大key_buffer_size
show variables like 'key_buffer_size';
show status like 'Qcache%'; -- mysql5.7.20开始遗弃这个功能，http://mysqlserverteam.com/mysql-8-0-retiring-support-for-the-query-cache/，mariaDB还可以用
SHOW VARIABLES LIKE '%query_cache%';
```

#### 设置cron.php

修改 /etc/itop/params

```
auth_user=admin
auth_pwd=adminpassword
```

修改 /etc/crontab

```
*/1 * * * * root /usr/bin/php /var/www/html/webservices/cron.php --param_file=/etc/itop/params >>/var/log/itop-cron.log 2>&1
```
