---
author: edxi
pubDatetime: "2018-02-02T08:08:08Z"
title: PowerShell 学习笔记
slug: PowerShell_Study
featured: false
draft: false
tags:
  - PowerShell
description: 这一篇主要目的其实是为炫耀下奚有米的工作环境(￣y▽,￣)╭其次才是总结一下这段时间写PowerShell的心得。 所以，先上奚有米工作图。 Look！ 豪华6屏联动！同时掌控5个操作系统（加上虚拟机7种操作系统）！老夫一把键盘游刃有余！  竖着的代码屏——VS Code的ZenMode。 Apple Air——Google/GitHub/stackover
canonicalURL: "https://edxi.github.io/2018/02/02/PowerShell_Study/"
---

这一篇主要目的其实是为炫耀下奚有米的工作环境(￣y▽,￣)╭  
其次才是总结一下这段时间写PowerShell的心得。

所以，先上奚有米工作图。  
![](http://poqwdbkil.bkt.clouddn.com/static/images/powershell_study/CodingMi.jpg)

Look！ 豪华6屏联动！同时掌控5个操作系统（加上虚拟机7种操作系统）！老夫一把键盘游刃有余！

*   竖着的代码屏——VS Code的ZenMode。
*   Apple Air——Google/GitHub/stackoverflow 复制！黏贴！
*   HP Elite——收收邮件开开会~填填表格写写文档，这就是为啥公司派的电脑配置再好也总是让人讨厌的原因~。
*   Dell XPS——可选，Ubuntu里Dock跑测试，当然实际上可以直接跑在工作机、虚拟机或云上面。
*   iPad——Slack上聊个天而已。
*   华为P9——还是微信最贴合国人需求。

### PowerShell DSC

目前工作环境还没有真的使用，这里留个沙发位给他。目前参考文档有：

*   [DCS官网文档](https://docs.microsoft.com/en-us/powershell/dsc/overview)——必不可少。
*   [DSC使用Pester和AppVeyor做测试](http://ramblingcookiemonster.github.io/Testing-DSC-with-Pester-and-AppVeyor/)——Warren F大神关于DCS测试的博客，编写复杂配置的时候，不妨使用这个方法测试。
*   [vSphereDCS系列](http://www.lucd.info/tag/vspheredsc/)——LucD大神嫁接vSphere的DCS实现，其中创意的把LCM放在一个独立的可以连接vcenter的服务器上（当然可以是vcenter本身），可惜目前项目进度感觉有点停滞了~

* * *

### Vester

这个开源项目着实解决了我的一些实际工作需求。  
[Vester](https://github.com/WahlNetwork/Vester)借助Pester实现对vSphere环境的检查(Test)，并且可以做相应的修复(Remediate)。当然检查和修复的脚本项目自身已经提供了不少，我在实际工作中也写了些，放在自己的[fork](https://github.com/edxi/Vester/tree/hashtable-support)里。  
主要补充了：

*   一些Host的Tests
*   支持配置使用HashTable

* * *

### Compare-HashTable

PowerShell自带的Compare-Object不能有效的比较HashTable，这里改写了网上某神的函数，实现递归的比较带嵌套的HashTable，代码如下：  

```
function Compare-Hashtable {
<#
.SYNOPSIS
Compare two Hashtable and returns an array of differences.
.DESCRIPTION
The Compare-Hashtable function computes differences between two Hashtables. Results are returned as
an array of objects with the properties: "key" (the name of the key that caused a difference), 
"side" (one of "<=", "!=" or "=>"), "lvalue" an "rvalue" (resp. the left and right value 
associated with the key).
.PARAMETER left 
The left hand side Hashtable to compare.
.PARAMETER right 
The right hand side Hashtable to compare.
.EXAMPLE
Returns a difference for ("3 <="), c (3 "!=" 4) and e ("=>" 5).
Compare-Hashtable @{ a = 1; b = 2; c = 3 } @{ b = 2; c = 4; e = 5}
.EXAMPLE 
Returns a difference for a ("3 <="), c (3 "!=" 4), e ("=>" 5) and g (6 "<=").
$left = @{ a = 1; b = 2; c = 3; f = $Null; g = 6 }
$right = @{ b = 2; c = 4; e = 5; f = $Null; g = $Null }
Compare-Hashtable $left $right
#>	
[CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Hashtable]$Left,

        [Parameter(Mandatory = $true)]
        [Hashtable]$Right		
	)
	
	function New-Result($Key, $LValue, $Side, $RValue) {
		New-Object -Type PSObject -Property @{
					key    = $Key
					lvalue = $LValue
					rvalue = $RValue
					side   = $Side
			}
	}
	[Object[]]$Results = $Left.Keys | % {
		if ($Left.ContainsKey($_) -and !$Right.ContainsKey($_)) {
			New-Result $_ $Left[$_] "<=" $Null
		} else {
			if ($Left[$_] -is [hashtable] -and $Right[$_] -is [hashtable] ) {
				Compare-Hashtable $Left[$_] $Right[$_]
			}
			else {
				$LValue, $RValue = $Left[$_], $Right[$_]
				if ($LValue -ne $RValue) {
					New-Result $_ $LValue "!=" $RValue
				}
			}
		}
	}
	$Results += $Right.Keys | % {
		if (!$Left.ContainsKey($_) -and $Right.ContainsKey($_)) {
			New-Result $_ $Null "=>" $Right[$_]
		} 
	}
	if ($Results -ne $null) { $Results }
}
```

* * *

### PSObject和HashTable互转

有个现成的[MSDN博客](https://blogs.msdn.microsoft.com/timid/2013/03/05/converting-pscustomobject-tofrom-hashtables/)提供了两个互转的函数。  
实际使用时[stackoverflow](https://stackoverflow.com/questions/3740128/pscustomobject-to-hashtable)里提供了两种方法也不错。  
首先时直接循环对象的属性：  

```
# Create a PSCustomObject (ironically using a hashtable)
$ht1 = @{ A = 'a'; B = 'b'; DateTime = Get-Date }
$theObject = new-object psobject -Property $ht1

# Convert the PSCustomObject back to a hashtable
$ht2 = @{}
$theObject.psobject.properties | Foreach { $ht2[$_.Name] = $_.Value }
```

还有就是如果须要转换嵌套对象，就使用这个函数：  

```
function ConvertPSObjectToHashtable { 
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

	 process {
		if ($InputObject -is [psobject]){
			$hash = @{}
			foreach ($property in $InputObject.PSObject.Properties){
				$hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
			}
			$hash
		}
		else{
			$InputObject
		}
	 } 
}
```

* * *

### 参数选项

这里墙裂推荐[PowerShell中文博客](http://www.pstips.net/)，标签云里提供了很多种参数用法。  
当然，参考[官方文档](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_parameters?view=powershell-5.1)总能有全面详细的参数使用帮助。

* * *

最后，农历狗年即将到来，预祝一下今年会旺_(੭_ˊᵕˋ)੭\*ଘ
