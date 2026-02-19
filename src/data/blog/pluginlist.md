---
author: edxi
pubDatetime: "2017-11-15T08:15:00Z"
title: 至今使用的插件列表
slug: pluginlist
featured: false
draft: false
tags:
  - hexo
description: 先播一段程序小猴奚有米的视频，嘿&lt;(￣︶￣)↗[GO!]A monkey hitting keys at random on a typewriter keyboard for an infinite amount of time will almost surely type a given text, such as the complete wo
canonicalURL: "https://edxi.github.io/2017/11/15/pluginlist/"
---

先播一段程序小猴奚有米的视频，嘿<(￣︶￣)↗\[GO!\]  
  

> A monkey hitting keys at random on a typewriter keyboard for an infinite amount of time will almost surely type a given text, such as the complete works of William Shakespeare.
> 
> **Émile Borel**[Infinite monkey theorem](https://en.wikipedia.org/wiki/Infinite_monkey_theorem)

  

#### 七牛图床

下载安装  

```
npm install hexo-qiniu-sync --save
```

修改\_config.yml  

```
qiniu:
  offline: false
  sync: true
  bucket: edxi
  access_key: AccessKey
  secret_key: SecretKey
  dirPrefix: static
  urlPrefix: http://ovdqer2rp.bkt.clouddn.com/static
  #up_host: http://upload.qiniu.com
  local_dir: static
  update_exist: true
  image:
    folder: images
    extend:
  js:
    folder: js
  css:
    folder: css
```

图片用PNGGauntlet无损压缩一下。然后放在hexo站点目录的static/image下（建议按blog名再建个目录，比如hexosite/static/image/blogname/cover.png），hexo g的时候会同步图片。  
使用方式：  

```
{% qnimg blogname/cover.png %}
```

* * *

#### asciinema录屏

下载安装  

```
npm install --save hexo-tag-asciinema
```

先按照[asciinema官方文档](https://asciinema.org/docs/how-it-works)完成录屏。  
录制完成后记录video\_id，比如下面这段录制的video\_id就是IGFqHfw0zbe2VckMU9niLY0mB  

```
# asciinema rec
~ Asciicast recording started.
~ Hit Ctrl-D or type "exit" to finish.
# [root@ansible01 _posts]# echo Hello xiyoumi
Hello xiyoumi
[root@ansible01 _posts]# exit
~ Asciicast recording finished.
~ Press <Enter> to upload, <Ctrl-C> to cancel.

https://asciinema.org/a/IGFqHfw0zbe2VckMU9niLY0mB
```

引用这个video就是  

```
{% asciinema video_id %}
```

* * *

#### flowchart流程图

下载安装  

```
npm install --save hexo-filter-flowchart
```

配置\_config.yml添加下面这段：  

```
flowchart:
  # raphael:   # optional, the source url of raphael.js
  # flowchart: # optional, the source url of flowchart.js
  options: # options used for `drawSVG`
```

使用的时候直接按照[flowchar.js官网](http://flowchart.js.org/)的语法写好流程就行

* * *

#### 添加脚注

下载安装：  

```
npm install hexo-reference --save
```

使用方法就直接参考github上的[README.md](https://github.com/quentin-chen/hexo-reference)吧，这里不再赘述。

* * *

#### Tag Plugins

这篇博客开头的youku是iframe，开头的猴子引言是blockquote，两者使用的是Hexo默认安装的[Tag Plugin](https://hexo.io/docs/tag-plugins.html)  
Tag的使用方法如下：

*   iframe
    
    ```
    <iframe src="url" width="[width][height]" height="300" frameborder="0" allowfullscreen></iframe>
    ```
    
*   blockquote
    
    ```
    {% blockquote [author[, source]] [link] [source_link_title] %}
    content
    {% endblockquote %}
    ```
    
*   另外，上面的iframe使用方法用codeblock实现的，哼哼( •̀ ω •́ )✧
    

* * *

#### 关于猴子~

最后，关于猴子，如果有兴趣研究的话~  
[https://en.wikipedia.org/wiki/Infinite\_monkey\_theorem](https://en.wikipedia.org/wiki/Infinite_monkey_theorem)
