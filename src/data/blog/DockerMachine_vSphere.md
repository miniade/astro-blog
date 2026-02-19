---
author: edxi
pubDatetime: "2018-07-09T18:18:18Z"
title: docker-machine使用vSphere驱动
slug: DockerMachine_vSphere
featured: false
draft: false
tags:
  - VMware
  - docker
description: 在使用docker-machine的时候，尝试了vSphere driver。Docker的vSphere Driver官方文档[1]比较晦涩，只是列出了支持的参数及其对应的环境变量。这里参照VMware BLOGS的一篇博客[2]作为例子测试通过。 顺便这里提一下，VMware也有自己的容器解决方案，叫VIC，每个容器都创建一个VM，通过VCH来模拟容器主
canonicalURL: "https://edxi.github.io/2018/07/09/DockerMachine_vSphere/"
---

在使用docker-machine的时候，尝试了vSphere driver。  
Docker的vSphere Driver官方文档[\[1\]](#fn:1)比较晦涩，只是列出了支持的参数及其对应的环境变量。  
这里参照VMware BLOGS的一篇博客[\[2\]](#fn:2)作为例子测试通过。

顺便这里提一下，VMware也有自己的容器解决方案，叫VIC，每个容器都创建一个VM，通过VCH来模拟容器主机，Admiral来管理，当然还集成了热门的Harbor作为registry，PhotonOS作为dockerOS。可以到官网上尝试下Hands-on Lab[\[3\]](#fn:3)。

### docker-machine安装

windows和macos就只要直接安装docker会带上，一般问题不大。  
之所以这里须要提一下，是因为linux上或者须要直接到官方github release页面下载的话，会涉及到墙的问题，当然可以用代理解决，如果不想用代理，那就须要把aws s3服务器在本地Hosts上指定成香港的，如下：  

```
[root@docker ~]# echo '219.76.4.4 github-cloud.s3.amazonaws.com' >> /etc/hosts

[root@docker ~]# curl -L https://github.com/docker/machine/releases/download/v0.15.0/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
>     chmod +x /tmp/docker-machine &&
>     sudo cp /tmp/docker-machine /usr/local/bin/docker-machine
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   617    0   617    0     0    701      0 --:--:-- --:--:-- --:--:--   701
100 26.8M  100 26.8M    0     0   328k      0  0:01:23  0:01:23 --:--:--  523k
```

### docker-machine创建vm

为了方便解释，这里直接把测试使用的环境变量罗列解释一下：  

```
export VSPHERE_VCENTER='hpshvcenter02.vpcsh.com.cn'    # vCenter IP/FQDN
export VSPHERE_USERNAME='administrator@vsphere.local'  # vCenter user 
export VSPHERE_PASSWORD='0!MoneyGomyHome'              # vCenter user password 
export VSPHERE_NETWORK='107'                           # PortGroup 这个网段要有DHCP，否则没法连上管理这个DOCKER MACHINE，这个有bug，必须要在docker-machine命令里使用参数
export VSPHERE_DATASTORE='SS8400/8400-1t'              # Datastore
export VSPHERE_DATACENTER='SHVPClab'                   # Datacenter name 
export VSPHERE_FOLDER='LabVM/labdockervm'              # VM folder
export VSPHERE_HOSTSYSTEM='SHVPClab/*'                 # could be ommited if DRS, cluster name (inside the datacenter)
```

可以看到，上面除了VSPHERE\_NETWORK，其他环境变量也就直接用好了，用起来都挺正常的。  
至于DHCP，这个我不知道有什么其他办法可以破，貌似docker-machine也没有参数可以在创建machine的时候指定IP的。

我引用的博客里还使用了docker-machine的swarm参数直接生成swarm cluster，这里就不再赘述了。

* * *

### 管理docker-machine

这里不罗嗦了，可以直接参看docker-machine的官方文档。

下面直接看下使用了vSphere环境变量后创建的效果。

```
admin@labdocker:~$ docker-machine create -d vmwarevsphere --vmwarevsphere-network="107" testvm
Running pre-create checks...
Creating machine...
(testvm) Copying /home/admin/.docker/machine/cache/boot2docker.iso to /home/admin/.docker/machine/machines/testvm/boot2docker.iso.                                     ..
(testvm) Generating SSH Keypair...
(testvm) Creating VM...
(testvm) Uploading Boot2docker ISO ...
(testvm) adding network: 107
(testvm) adding network: 107
(testvm) Reconfiguring VM
(testvm) Waiting for VMware Tools to come online...
(testvm) Provisioning certs and ssh keys...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with boot2docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: docker-machine env testvm
admin@labdocker:~$ docker-machine ls
NAME     ACTIVE   DRIVER          STATE     URL                       SWARM   DOCKER        ERRORS
testvm   -        vmwarevsphere   Running   tcp://10.252.7.176:2376           v18.05.0-ce
```

然而，DHCP因为可能会分配vm新的IP，这就会导致下面这个报错。

```
admin@labdocker:~$ docker-machine ls
NAME     ACTIVE   DRIVER          STATE     URL                       SWARM   DOCKER    ERRORS
testvm   -        vmwarevsphere   Running   tcp://10.252.7.175:2376           Unknown   Unable to query docker version: Get https:                                     //10.252.7.175:2376/v1.15/version: x509: certificate is valid for 10.252.7.176, not 10.252.7.175
```

这也属于比较常见的问题，通过重新生成连接证书来解决。

```
admin@labdocker:~$ docker-machine regenerate-certs testvm
Regenerate TLS machine certs?  Warning: this is irreversible. (y/n): y
Regenerating TLS certificates
Waiting for SSH to be available...
Detecting the provisioner...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
```

其他使用下来也都一切正常，用完删掉，over了事~（毕竟docker-machine还是作为测试环境比较好，正式环境最好还是上文首VIC这类方案比较好）

```
admin@labdocker:~$ docker-machine rm testvm
About to remove testvm
WARNING: This action will delete both local reference and remote instance.
Are you sure? (y/n): y
Successfully removed testvm
```
