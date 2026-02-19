---
author: edxi
pubDatetime: "2018-07-09T18:18:18Z"
title: Infrastructure as code - 尝试Terraform管理vSphere
slug: Terraform_vSphere
featured: false
draft: false
tags:
  - VMware
  - Terraform
description: 使用AWS几乎少不了用到CloudFormation，可能更加知名的是可以用在近百个不同平台上的Terraform，这类软件是Infrastructure as code很好的实践。 出于日常管理vSphere的须要，尝试了使用Terraform管理vSphere。（非常巧合的是，接下来几天，也就是上周五参加的AWS summit的DevOps主题会场里，有
canonicalURL: "https://edxi.github.io/2018/07/09/Terraform_vSphere/"
---

使用AWS几乎少不了用到CloudFormation，可能更加知名的是可以用在近百个不同平台上的Terraform，这类软件是Infrastructure as code很好的实践。

出于日常管理vSphere的须要，尝试了使用Terraform管理vSphere。（非常巧合的是，接下来几天，也就是上周五参加的AWS summit的DevOps主题会场里，有位大牛介绍一个github项目[trident](https://github.com/mixslice/trident)，就用的Terraform为核心管理AWS上运行的K8S（目前不是EKS））

顺便提一下，之前用PowerCLI写过一个[批量创建虚拟机的脚本](https://edxi.github.io/2017/12/21/powercli_vmdeploy/)，了解terraform后多少觉得自己有点重复造轮子的意思了，但实际用下来terraform在大批量写JSON也着实非常费力，某种程度还不如csv表格方便，所以个人认为Infrastructure as code的主要目标还是为了通过模板化的方式部署Infrastructure并保持幂等性。可能在terraform的import功能更强大后，可以实现直接把现有系统导入成JSON吧（目前只是导入state）。

### Terraform相关概念

总的来说，terraform就是个工具软件，运行在自己的笔记本上，创建个目录写一段规定格式的JSON文件（也可以是多个，会逐个读取），里面根据对应provider给出的data source和resource写上配置内容，terraform就会根据配置去下载对应的provider plugin，并连接对应Provider目标执行操作，比如操作vSphere provider支持Virtual Machine/Host and Cluster/Networking/Storage…等resources。具体必须参考结合官方文档来[\[1\]](#fn:1)使用。

这个表格罗列解释下相关概念。

名词

解释

.tf或.tf.json文件

terraform配置文件的扩展名，执行terraform命令会读取当前目录所有该扩展名的文件内容

\*override.tf

该文件内容如果和其他配置文件里的内容重复，会覆盖之前的配置

Provider

就是这个terraform配置要操作的目标Infrastructure，比如aws、Heroku等等

State

运行terraform会生成.state文件，作为连接目标Infrastructure产生的对应状态映射，包括现有和导入的资源，以及资源是否须要增删改

Provisioner

用来在执行terraform apply的时候在本地或远程执行脚本

Resource/资源

根据不同的provider，定义不同的资源，比如aws的ec2，vsphere的vm

Data Source/数据源

由于资源存在依赖性（比如vm须要有network和datastore），这些资源可能已经在Infrastructure里存在，通过定义Data Source来匹配现有资源

Variable/变量

定义在.tf配置或.tfvar参数文件中，通过直接赋默认值、插值语法、命令行参数-var/-varfile、环境变量TF_VAR_\*的方式赋值

Output/输出

用来在terraform apply运行中输出内容，比如输出ec2的AMI ID

Local Value/本地值

本地值存储一个表达式，类似于本地变量，可以在模块中被反复使用

Config Syntax/配置语法

用来定义变量和资源的JSON语句块，是HashiCorp定义的一种语言HCL

Interpolation Syntax/插值语法

配置文件中 ${} 包裹的值，使用不同的变量/条件/函数可以用来处理最终输出的值

Module/模块

预定义好得一组配置，在terraform registry已经有很多写好得module

* * *

### Terraform vSphere Provider

这里用terraform创建folder和datastore作为例子。

#### 创建folder

先创建一个目录，并写一个.tf文件，定义现有环境的vSphere相关的Provider。

```
provider "vsphere" {
  user           = "${var.vsphere_user}"
  password       = "${var.vsphere_password}"
  vsphere_server = "${var.vsphere_server}"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}


data "vsphere_datacenter" "dc" {
  name = "${lookup(var.datacenter, var.vsphere_server)}"
}

resource "vsphere_folder" "vmfolder_test" {
  path          = "vmfolder"
  type          = "vm"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
resource "vsphere_folder" "datastorefolder-test" {
  path          = "vmdatastorefolder"
  type          = "datastore"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
```

上面这段内容可以看到：

*   这里定义的vSphere Provider里须要user/password/vsphere\_server这些参数，这里用了${}的语法调用参数，以适合不同情况的变量。
    
*   使用data “vsphere\_datacenter”定义了个datacenter的data source，这个data source在之后的两个resource中作为其所需参数的值引用。
    
*   这里vsphere\_datacenter所需的name参数，使用了lookup的插值语法来查找最终的值，这样在连接不同的vcenter时就会调用不同的datacenter名字了。这里的变量定义可以放在了另外一个.tf文件里（或者.tfvar文件），内容可以如下：
    
    ```
    variable "datacenter"{
      type = "map"
      default = {
        "10.0.0.123" = "DSD1"
        "10.0.0.124" = "DSD2"
        "192.168.123.123" = "PRODDMZ"
        "192.168.124.123" = "DRDMZ"
      }
    }
    ```
    

接下来执行下面几步就可以完成这两个folder的创建：

1.  在这个目录中执行terraform init就会根据这个.tf所引用的vSphere Provider下载所需的plugin。
2.  (可选) 执行terraform plan会列出可能的系统修改，
3.  执行terraform apply就会实施目录创建，在命令行交互中输入yes确认后就会在目标vSphere上应用修改。

那么这里就会有另外一个问题了，如果现在须要创建的folder已经存在了，那么这里还能成功执行上述命令吗？  
这里就涉及到.state文件了：

*   在terraform目录下，初始情况下，**由于从未连接过目标infra，所以.state文件不存在**，在我们这个例子里，也就是**terraform这时候不知道目标vSphere是否已经存在，这个时候执行terraform apply命令会失败**。
*   这个时候**可以通过执行terraform import命令，导入相应的resource到.state中，使terraform apply执行时可以知道对应资源已经存在**，参考这里对应folder resource的文档[\[2\]](#fn:2)，大致命令格式就这样 terraform import vsphere\_folder.folder /default-dc/vm/terraform-test-folder
*   当然，如果所需创建的folder不存在，在执行了一次terraform apply之后，该目录会创建，并且terraform本地的.state文件也会记录该目录创建了，也就是已存在，之后再反复执行terraform apply是也就不会失败了。（会按照terraform的幂等特性将对应resource修改成.tf文件中所定义的）

#### 创建datastore

datastore的创建方法和folder相符，无非是所需的data source有所不同，这里简单举例如下：

```
data "vsphere_host" "esxi_host" {
  name          = "cnsd11espif001b.dir.saicgmac.com"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_vmfs_disks" "available-vmdisk" {
  host_system_id = "${data.vsphere_host.esxi_host.id}"
  rescan         = true
  filter         = "naa.600601606de036009a3c2a90567fe811"
}

resource "vsphere_vmfs_datastore" "testdatastore" {
  name           = "testdatastore"
  host_system_id = "${data.vsphere_host.esxi_host.id}"
  folder         = "vmdatastorefolder"

  disks = ["${data.vsphere_vmfs_disks.available-vmdisk.disks}"]
}
```

上面这段可以是单独的.ft文件，只要存放在同一个terraform目录即可，由于所需依赖关系terraform会自行处理，所以这里只要定义目标vSphere所需的最终资源状态就行了。

* * *

使用terraform创建vSphere资源这里也就举两个例子，官方文档有创建AWS资源的get start可以尝试，当然我就不赘述了，相对的，我计划接下来会写如何AWS原生的CloudFormation，尽情期待ヾ(≧▽≦\*)o
