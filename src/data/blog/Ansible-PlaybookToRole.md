---
author: edxi
pubDatetime: "2017-10-04T16:00:00Z"
title: Ansible学习笔记--从Playbook创建Role
slug: Ansible-PlaybookToRole
featured: false
draft: false
tags:
  - ansible
description: 下面以一个现成的playbook为例，将其内容分解并编排成一个role。 整个步骤的终端录屏
canonicalURL: "https://edxi.github.io/2017/10/04/Ansible-PlaybookToRole/"
---

下面以一个现成的playbook为例，将其内容分解并编排成一个role。

整个步骤的终端录屏

* * *

### 现有playbook

```
- hosts: localhost
  sudo: true
  vars:
    baserepo: ''
    updatesrepo: ''
    extrasrepo: ''

# Task setup local repositories
  tasks:
  - name: Remove repository (and clean up left-over metadata)
    yum_repository:
      name: packages
      state: absent
    notify: yum-clean-metadata

  - name: Add yumserver repository
    template: "src=yumserver.repo dest=/etc/yum.repos.d/yumserver.repo owner=root group=root mode=0644"

  - name: Add epel repository with proxy
    yum_repository:
      name: epel
      description: EPEL YUM repo
      proxy: "http://{{ proxyserver }}:{{ proxyport }}"
      baseurl: http://mirrors.aliyun.com/epel/7/$basearch
      failovermethod: priority
      gpgcheck: no
    when: proxyserver is defined and proxyport is defined and proxyserver != '' and proxyport != ''
  - name: Add epel repository without proxy
    yum_repository:
      name: epel
      description: EPEL YUM repo
      baseurl: http://mirrors.aliyun.com/epel/7/$basearch
      failovermethod: priority
      gpgcheck: no
    when: proxyserver is not defined proxyserver == ''
    tags: epel_repo

# Handler clean yum metadata cache
  handlers:
  - name: yum-clean-metadata
    command: yum clean metadata
    args:
      warn: no
```

上面playbook的作用是设置yum repository。

除了hosts以外，大致分成三个部分：

*   vars——指定了playbook须要用到的变量
*   tasks——具体playbook运行的module，具体执行了
    *   先清理package repository并提醒handler执行metadata清理
    *   通过template module设置的base/updates/extras repository
    *   用yum\_repository module设置epel
*   handlers——定义了作为handler被调用的module

这里在tasks里有个template module，对应的template如下：

```
[base]
name=CentOS-$releasever - Base
{% if baserepo is defined and baserepo != '' %}
baseurl={{ baserepo }}
{% else %}
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
{% endif %}
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
{% if proxyserver is defined and proxyserver != '' and proxyport is defined and baserepo == '' %}
proxy=http://{{ proxyserver }}:{{proxyport}}
{% endif %}

#released updates
[updates]
name=CentOS-$releasever - Updates
{% if updatesrepo is defined and updatesrepo != '' %}
baseurl={{ updatesrepo }}
{% else %}
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
{% endif %}
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
{% if proxyserver is defined and proxyserver != '' and proxyport is defined and updatesrepo == '' %}
proxy=http://{{ proxyserver }}:{{proxyport}}
{% endif %}

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
{% if extrasrepo is defined and extrasrepo != '' %}
baseurl={{ extrasrepo }}
{% else %}
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
{% endif %}
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
{% if proxyserver is defined and proxyserver != '' and proxyport is defined and extrasrepo == '' %}
proxy=http://{{ proxyserver }}:{{proxyport}}
{% endif %}
```

* * *

### 创建role

#### 创建目录结构

role的固定目录结构如下

```
[root@ansible01 examplePlaybook]# mkdir yumrepo                                                                        
[root@ansible01 examplePlaybook]# # this is the role main directory
[root@ansible01 examplePlaybook]# cd yumrepo
[root@ansible01 yumrepo]# mkdir tasks
[root@ansible01 yumrepo]# mkdir handlers
[root@ansible01 yumrepo]# mkdir defaults
[root@ansible01 yumrepo]# mkdir vars
[root@ansible01 yumrepo]# mkdir files
[root@ansible01 yumrepo]# mkdir templates
[root@ansible01 yumrepo]# mkdir meta
[root@ansible01 yumrepo]# ll
total 0
drwxr-xr-x. 2 root root 6 Oct  4 15:47 defaults
drwxr-xr-x. 2 root root 6 Oct  4 15:47 files
drwxr-xr-x. 2 root root 6 Oct  4 15:47 handlers
drwxr-xr-x. 2 root root 6 Oct  4 15:47 meta
drwxr-xr-x. 2 root root 6 Oct  4 15:47 tasks
drwxr-xr-x. 2 root root 6 Oct  4 15:47 templates
drwxr-xr-x. 2 root root 6 Oct  4 15:47 vars
```

#### 设置默认变量

创建defaults目录里的main.yml用于设置默认变量。

在这个例子里，直接把playbook里用到的几个变量复制进去。

#### 设置tasks

创建tasks目录里的main.yml用于执行roles所调用的任务。

在这个例子里，直接把playbook里用到的几个任务复制了进去。 也可以讲不同功能的任务单独写成yml文件，然后通过在main.yml里使用include来调用（并可以使用when条件判断使用哪个任务，还可以使用tags方便在执行时调用对应功能的任务）

#### 设置handlers

创建handlers目录里的main.yml用于执行tasks所调用的handler。

在这个例子里，直接把playbook里用到的handler复制了进去。

#### 复制template文件

由于原有playbook使用到template module，所以须要把roles使用的template文件yumserver.yml复制到template目录。

#### 测试role

通过上面改写，自建的role已经完成，写一个简单的playbook用来测试

```
- hosts: localhost
  roles:
    - yumrepo
```

执行playbook查看结果

```
[root@ansible01 examplePlaybook]# ansible-playbook test.yml

PLAY [localhost] ******************************************************************************************************

TASK [Gathering Facts] ************************************************************************************************
ok: [localhost]

TASK [yumrepo : Remove repository (and clean up left-over metadata)] **************************************************
ok: [localhost]

TASK [yumrepo : Add yumserver repository] *****************************************************************************
changed: [localhost]

TASK [yumrepo : Add epel repository with proxy] ***********************************************************************
skipping: [localhost]

TASK [yumrepo : Add epel repository without proxy] ********************************************************************
ok: [localhost]

PLAY RECAP ************************************************************************************************************
localhost                  : ok=4    changed=1    unreachable=0    failed=0
```

可以修改测试playbook，加上参数以覆盖roles的默认参数

```
- hosts: localhost
  vars:
    baserepo: "http://repo.aliyun.com/yum/"
  roles:
    - yumrepo
```

再次执行就会按照上述不同的参数修改repository了。

### 总结

大致总结下，role的目的是为了可以在各种环境下重用，把 vars, tasks, handlers等等playbook的组成元素放到固定的目录结构里。

更加详细的使用方法当然还是要参考了[官方文档](http://docs.ansible.com/ansible/latest/playbooks_reuse_roles.html)。

* * *

> 纸上得来终觉浅，绝知此事要躬行。
