---
author: edxi
pubDatetime: "2017-10-10T15:46:00Z"
title: Ansible学习笔记--python编写读取excel的dynamic inventory
slug: Ansible-excel-inventory
featured: false
draft: false
tags:
  - ansible
  - python
description: Ansible提供了自己写脚本实现获取inventory的方法，直接通过github下载ansible源码，在/ansible/contrib/inventory目录里有不少现成的dynamic inventory，比如ec2、cobbler、openstack等等，可以直接从对应系统读取ansible须要管理的主机信息。这里要实现得dynamic inve
canonicalURL: "https://edxi.github.io/2017/10/10/Ansible-excel-inventory/"
---

Ansible提供了自己写脚本实现获取inventory的方法，直接通过github下载ansible源码，在/ansible/contrib/inventory目录里有不少现成的dynamic inventory，比如ec2、cobbler、openstack等等，可以直接从对应系统读取ansible须要管理的主机信息。这里要实现得dynamic inventory是从excel里读取主机信息（可能因为功能太low了，这么多contribute里面居然没有，于是自己写脚本实现一个）。

### Dynamic Inventory介绍

[官方文档](http://docs.ansible.com/ansible/latest/intro_dynamic_inventory.html)大致介绍了用途，这里再简单赘述一下。

#### Dynamic Inventory结构

参照[官方文档](http://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html)，dynamic inventory结构为一个JSON格式，里面分为分组字典和\_meta字典两部分。

##### 分组字典

分组即主机列表的分组，可以包括对应分组的变量，官方示例如下：

```
{
    "databases": {
        "hosts": ["host1.example.com", "host2.example.com"],
        "vars": {
            "a": true
        }
    },
    "webservers": ["host2.example.com", "host3.example.com"],
    "atlanta": {
        "hosts": ["host1.example.com", "host4.example.com", "host5.example.com"],
        "vars": {
            "b": false
        },
        "children": ["marietta", "5points"]
    },
    "marietta": ["host6.example.com"],
    "5points": ["host7.example.com"]
}
```

可以使用all分组存放所有其他分组或主机

##### \_meta字典

\_meta字典作用是存放所有主机的变量，JSON格式如下：

```
{

    # results of inventory script as above go here
    # ...

    "_meta": {
        "hostvars": {
            "moocow.example.com": {
                "asdf" : 1234
            },
            "llama.example.com": {
                "asdf": 5678
            }
        }
    }
}
```

#### Dynamic Inventory调用

##### 两种inventory plugin

Ansible在使用Inventory时会尝试调用两种plugin，一种默认使用的ini plugin，另一种就是dynamic inventory使用的script plugin。所以在使用dynamic inventory的时候，本质上并不需要特别指定目前使用的inventory文件时ini还是一个script文件，和调用ini的inventory完全一样，用以下方式指定dynamic inventory脚本文件名即可：

*   命令参数方式——例如 ansible -i xl-inventory.py webserver:dbserver -m ping，命令里面直接通过-i指定xl-inventory.py这个脚本，每次调用该脚本生成JSON字典格式的inventory。
    
*   config文件——例如配置/etc/ansible/ansible.cfg文件的inventory = /etc/ansible/xl-inventory.py
    
*   环境变量——例如export ANSIBLE\_INVENTORY=~/xl-inventory.py
    

##### 脚本参数

作为输出JSON字典的脚本，要求提供两个参数：

*   list——用来返回整个JSON字典。
*   host——用来返回指定host的variable。

两个参数都是强制要求的，但是由于使用\_meta已经可以为每个Host提供variable，所以这时候host实际上可以返回个空字典。

* * *

### Dynamic Inventory脚本

知道了dynamic inventory结构后，就编写脚本输出该JSON格式。（应该输出yaml格式也是可以的，我这里没有实际测试过）

#### excel inventory示例

这里用python写了脚本，功能是

1.  把excel读取出来
2.  指定某列为主机
3.  其他列为meta的host vars
4.  而且可以将某些列作为分组组名
5.  组名会读取指定group vars目录对应的分组yaml文件
6.  上面这些excel的信息通过一个ini文件指定
7.  最终组成一个dict输出

excel表格示例如下：

IP

Host Name

OS Version

Status

Function

192.168.1.10

host1

CentOS 6.9

Active

ELKstack

192.168.1.11

host2.test.lab

CentOS 7

Inactive

ELKstack

192.168.1.12

host3.test.lab

Windows 2012R2

Active

ADDS

假设指定IP列为inventory的主机，OS Version、Status和Function三列都作分组，并且有ELKstack和Windows 2012R2两个group vars文件，期望结果示例JSON如下：

```
{
    "all": {
        "hosts": [
            "192.168.1.10",
            "192.168.1.11",
            "192.168.1.12"
        ],
        "vars": {}
    },
    "Active": {
        "hosts": [
            "192.168.1.10",
            "192.168.1.12"
        ],
        "vars": {}
    },
    "Inactive": {
        "hosts": [
            "192.168.1.11"
        ],
        "vars": {}
    },
    "CentOS 6.9": {
        "hosts": [
            "192.168.1.10"
        ],
        "vars": {}
    },
    "CentOS 7": {
        "hosts": [
            "192.168.1.11"
        ],
        "vars": {}
    },
    "Windows 2012R2": {
        "hosts": [
            "192.168.1.12"
        ],
        "vars": {
            "ansible_winrm_realm": "test.lab",
            "ansible_winrm_transport": "kerberos",
            "ansible_port": 5986,
            "ansible_connection": "winrm",
            "ansible_winrm_server_cert_validation": "ignore"
        }
    },
    "ELKstack": {
        "hosts": [
            "192.168.1.10",
            "192.168.1.11"
        ],
        "vars": {
            "proxyserver": "192.168.1.80",
            "proxyport": 8080,
            "resolv_nameservers": [
                "192.168.1.12",
                "8.8.8.8"
            ]
        }
    },
    "ADDS": {
        "hosts": [
            "192.168.1.12"
        ],
        "vars": {}
    },
    "_meta": {
        "hostvars": {
            "192.168.1.10": {
                "IP": "192.168.1.10",
                "Host_Name": "host1",
                "OS_Version": "CentOS 6.9",
                "Status": "Active",
                "Function": "ELKstack"
            },
            "192.168.1.11": {
                "IP": "192.168.1.11",
                "Host_Name": "host2.test.lab",
                "OS_Version": "CentOS 7",
                "Status": "Inactive",
                "Function": "ELKstack"
            },
            "192.168.1.12": {
                "IP": "192.168.1.12",
                "Host_Name": "host3.test.lab",
                "OS_Version": "Windows 2012R2",
                "Status": "Active",
                "Function": "ADDS"
            }
        }
    }
}
```

#### 脚本程序流程

#### 脚本代码

```
# -*- coding: utf-8 -*-
import argparse
import configparser
import json
import xlrd
import os
import yaml


def open_excel(file):
    try:
        data = xlrd.open_workbook(file)
        return data
    except Exception as e:
        print(str(e))


def inventory_group(ws, inventory={}, host_column=0, group_column=-1):
    # 功能——按指定列分组主机
    """
    实现——先初始化该列的hash，初始化时如该组名在group_vars_file_list里有，同时初始化vars
    再逐行将主机列的值append到list里
    :param ws: excel的worksheet，作为输入数据源
    :param inventory: 最终要输出的inventory字典，将数据添加到该字典
    :param host_column: inventory的Host或IP列号
    :param group_column: 如果须要按照某列分组，提供分组使用的列号
    :return: 添加excel数据后的Inventory
    """
    if group_column == -1:
        inventory['all'] = {'hosts': [], 'vars': {}}
        for i in range(ws.nrows - 1):
            inventory['all']['hosts'].append(ws.cell_value(i + 1, host_column))
    else:
        group_vars_file_list = next(os.walk(config['Excel Inventory']['group_vars_dir']))[2]
        for i in ws.col_values(group_column, 1):
            if i in group_vars_file_list:
                inventory[i] = {'hosts': [], 'vars': yaml.load(open(config['Excel Inventory']['group_vars_dir']+'/'+i))}
            else:
                inventory[i] = {'hosts': [], 'vars': {}}
        for i in range(ws.nrows - 1):
            inventory[ws.cell_value(i + 1, group_column)]['hosts'].append(ws.cell_value(i + 1, host_column))
    return inventory


def ExcelInventory():
    wb = xlrd.open_workbook(filename=config['Excel Inventory']['file_name'])
    ws = wb.sheet_by_name(config['Excel Inventory']['sheet_name'])
    column_hash = {}
    for i in range(ws.ncols):
        column_hash[ws.cell_value(0, i)] = i
    host_column_name = column_hash[config['Excel Inventory']['host_column_name']]

    # 初始化一个包括所有主机的all group
    # inventory_hash = {ws.cell_value(0, host_column_name): {'hosts': host_list, 'vars': {}}}
    inventory_hash = inventory_group(ws, host_column=host_column_name)
    # 按照Group Column例举的列分组
    for item in config['Group Column']:
        inventory_hash = inventory_group(ws, host_column=host_column_name, group_column=column_hash[item])

    # 功能——将IP对应的行的所有列作为_mata的hostvars值
    # 实现——外层循环将每一行的IP作为key内层循环的hash作为value，内层循环将该列的第一行作为key当前行作为value
    host_list = ws.col_values(host_column_name, start_rowx=1)
    hostvars = {}
    for i in range(ws.nrows - 1):
        varscollumn = {}
        for j in range(ws.ncols):
            varscollumn[ws.cell_value(0, j).replace(' ', '_')] = ws.cell_value(i + 1, j)
        hostvars[host_list[i]] = varscollumn
    inventory_hash['_meta'] = {'hostvars': hostvars}

    return inventory_hash


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--list', help='hosts list', action='store_true')
    parser.add_argument('-H', '--host', help='hosts vars')
    args = vars(parser.parse_args())

    config = configparser.ConfigParser()
    config.optionxform = str
    config.read('./xl-inventory.ini')

    if args['list']:
        print(json.dumps(ExcelInventory(), indent=4))
    elif args['host']:
        print(json.dumps({'_meta': {'hostvars': {}}}))
    else:
        parser.print_help()
```

#### 配置文件

```
[Excel Inventory]
file_name = ./sample.xlsx
sheet_name = Sheet1
host_column_name = IP
group_vars_dir = .

# Column(s) which need to define group. Only need key. Value will be ignored.
[Group Column]
# List only column name
Status =
OS Version =
Function =
```

st=>start: Start|past e=>end: End op1=>operation: 从ini初始化配置|past op2=>operation: 打印帮助|current op3=>operation: 读取excel分组|current op4=>operation: 添加meta到dict|current sub1=>subroutine: 添加主机分组dict|invalid cond=>condition: 脚本参数 使用--list|approved c2=>condition: 脚本参数 使用--host|rejected c3=>condition: 主机分组 添加完成?|approved io=>inputoutput: 输出空JSON|request io2=>inputoutput: 输出dict到JSON|request st->op1(right)->cond cond(no, right)->c2 cond(yes)->op3 op3->c3 c3(no, left)->sub1 sub1(left)->op3 c3(yes)->op4->io2->e c2(yes)->io->e c2(no)->op2->e{"theme":"simple","scale":1,"line-width":2,"line-length":50,"text-margin":10,"font-size":12}
