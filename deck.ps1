# ============================================================
#  deck.ps1 —— 《项目方案交流文件.html》制作小工具
#  用法（在本目录打开 PowerShell）：
#    体检：      .\deck.ps1 check
#    新增一页：  .\deck.ps1 new -Id portal -Title "让课程门户<em>会引路</em>" -Nav "门户" -Eyebrow "建设方案 · 基座" -Note "右上角引导语" -Take "本页结论一句话" -After plan -Layout side
#  -Layout：side=左窄右宽   2=等宽两栏   3=三栏
#  -After ：插在哪一页的 id 后面；省略=追加到最后
#  脚本自动：搭骨架 + 注册 PAGES + 重排眉标序号(01/02…) + 重排"第 N 页"注释
#  （右下角页码由播放器按 PAGES 顺序自动生成，无需维护）
# ============================================================
param(
  [Parameter(Position=0)][string]$Cmd = 'check',
  [string]$File,
  [string]$Id, [string]$Title, [string]$Nav,
  [string]$Eyebrow, [string]$Note, [string]$Take, [string]$After,
  [ValidateSet('side','2','3')][string]$Layout = 'side'
)
$ErrorActionPreference = 'Stop'
if (-not $File) { $File = Join-Path $PSScriptRoot '项目方案交流文件.html' }
$VALID = '^[A-Za-z][A-Za-z0-9_-]*$'
if (-not (Test-Path -LiteralPath $File)) { throw "找不到 HTML 文件：$File" }
$t = [System.IO.File]::ReadAllText($File, [System.Text.Encoding]::UTF8)
$nl = if ($t.Contains("`r`n")) { "`r`n" } else { "`n" }

function Get-PageIds([string]$text) {
  $m = [regex]::Match($text, "(?s)var PAGES\s*=\s*\[(.*?)\];")
  if (-not $m.Success) { throw '找不到 PAGES 数组' }
  return ,@([regex]::Matches($m.Groups[1].Value, "\{[^{}]*id:'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
}
function Get-Sections([string]$text) {
  $ms = @([regex]::Matches($text, '(?s)<section class="(?<cls>[^"]*)" id="(?<id>[^"]+)">.*?</section>') |
          Where-Object { $_.Groups['id'].Value -cmatch '^[A-Za-z][A-Za-z0-9_-]*$' })
  return ,$ms
}
function Renumber([string]$text) {
  # 眉标序号：封面不编号，其余按出现顺序 01、02……
  $ctr = @{ n = 0 }
  $text = [regex]::Replace($text, '(?s)<section class="(?<cls>[^"]*)" id="(?<id>[^"]+)">.*?</section>', {
    param($mm)
    if ($mm.Groups['id'].Value -cnotmatch '^[A-Za-z][A-Za-z0-9_-]*$') { return [string]$mm.Value }
    $ctr.n = $ctr.n + 1
    $s = $mm.Value
    if ($mm.Groups['cls'].Value -notmatch 'cover') {
      $no = '{0:D2}' -f ($ctr.n - 1)
      $s = [regex]::Replace($s, '<span class="no">\d+</span>', ('<span class="no">' + $no + '</span>'))
    }
    return [string]$s
  })
  # 源码注释：<!-- ========== 第 N 页 · 名称 ========== -->
  $ktr = @{ n = 0 }
  $text = [regex]::Replace($text, '<!-- =+ \u7b2c \d+ \u9875 \u00b7 (?<name>.+?) =+ -->', {
    param($mm)
    $ktr.n = $ktr.n + 1
    return [string]('<!-- ========== ' + [char]0x7B2C + ' ' + $ktr.n + ' ' + [char]0x9875 + ' ' + [char]0xB7 + ' ' + $mm.Groups['name'].Value + ' ========== -->')
  })
  return $text
}

# ---------- snap（发版前快照，防止改坏回不去） ----------
if ($Cmd -eq 'snap') {
  $dir = Join-Path $PSScriptRoot 'versions'
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  $name = [IO.Path]::GetFileNameWithoutExtension($File)
  $dst = Join-Path $dir ($name + '_' + (Get-Date -Format 'yyyyMMdd_HHmm') + '.html')
  Copy-Item -LiteralPath $File -Destination $dst
  Write-Host ('已快照： ' + $dst)
  return
}

if ($Cmd -eq 'new') {
  foreach ($p in 'Id','Title','Nav') { if (-not (Get-Variable -Name $p -ValueOnly)) { throw "缺少参数 -$p" } }
  if ($Id -cnotmatch $VALID) { throw "Id 只能用字母/数字/-/_，且以字母开头：$Id" }
  if ((Get-Sections $t | ForEach-Object { $_.Groups['id'].Value }) -ccontains $Id) { throw "id 已存在：$Id，换一个" }
  if (-not $Eyebrow) { $Eyebrow = $Nav }
  if (-not $Note)   { $Note   = '右上角引导语：用一句话说明本页想让对方带走什么。' }
  if (-not $Take)   { $Take   = '本页结论一句话（写给交流对象）。' }

  function Panel([string]$zh, [string]$en) {
    return @"
        <div class="panel" style="flex:1;">
          <div class="panel-title"><span>$zh</span><span>$en</span></div>
          <ul class="list">
            <li><b>要点一：</b>在此填写……</li>
            <li><b>要点二：</b>在此填写……</li>
          </ul>
        </div>
"@
  }
  $q = '"'
  $body = switch ($Layout) {
    'side' { "    <div class=${q}slide-body g-side${q}>$nl      <div class=${q}col${q}>$nl$(Panel '左侧面板' 'LEFT')$nl      </div>$nl      <div class=${q}col${q}>$nl$(Panel '右侧面板' 'RIGHT')$nl      </div>$nl    </div>" }
    '2'    { "    <div class=${q}slide-body g-2${q}>$nl$(Panel '面板一' 'BLOCK 1')$nl$(Panel '面板二' 'BLOCK 2')$nl    </div>" }
    '3'    { "    <div class=${q}slide-body g-3${q}>$nl$(Panel '面板一' 'BLOCK 1')$nl$(Panel '面板二' 'BLOCK 2')$nl$(Panel '面板三' 'BLOCK 3')$nl    </div>" }
  }

  $sec  = "  <!-- ========== " + [char]0x7B2C + " 99 " + [char]0x9875 + " " + [char]0xB7 + " $Nav ========== -->$nl"
  $sec += "  <section class=${q}slide${q} id=${q}$Id${q}>$nl"
  $sec += "    <header class=${q}slide-head${q}>$nl"
  $sec += "      <div>$nl"
  $sec += "        <div class=${q}eyebrow${q}><span class=${q}no${q}>00</span>$Eyebrow</div>$nl"
  $sec += "        <h2 class=${q}slide-title${q}>$Title</h2>$nl"
  $sec += "      </div>$nl"
  $sec += "      <p class=${q}head-note${q}>$Note</p>$nl"
  $sec += "    </header>$nl"
  $sec += "    <div class=${q}head-rule${q}></div>$nl$nl"
  $sec += "$body$nl$nl"
  $sec += "    <div class=${q}take${q}>$nl"
  $sec += "      <div class=${q}take-label${q}>" + [char]0x8981 + [char]0x70B9 + "</div>$nl"
  $sec += "      <p>$Take</p>$nl"
  $sec += "    </div>$nl"
  $sec += "  </section>"

  $pageIds = Get-PageIds $t
  if (-not $After) { $After = $pageIds[-1] }
  if ($pageIds -cnotcontains $After) { throw "-After 指定的 id 不在 PAGES 里：$After" }

  $m = [regex]::Match($t, '(?s)<section class="[^"]*" id="' + [regex]::Escape($After) + '">.*?</section>')
  if (-not $m.Success) { throw "在正文里找不到该 section：$After" }
  $pos = $m.Index + $m.Length
  $t = $t.Substring(0, $pos) + $nl + $nl + $sec + $t.Substring($pos)

  $pat = "(?m)^[ \t]*\{[^{\r\n]*id:'" + [regex]::Escape($After) + "'[^}\r\n]*\}[ \t]*,?"
  $mp = [regex]::Match($t, $pat)
  if (-not $mp.Success) { throw "PAGES 里找不到这一行：$After" }
  $line = $mp.Value.TrimEnd()
  $hadComma = $line.EndsWith(',')
  if (-not $hadComma) { $line = $line + ',' }
  $entry = "  { id:'" + $Id + "',     nav:'" + $Nav + "' }" + $(if ($hadComma) { ',' } else { '' })
  $t = $t.Substring(0, $mp.Index) + $line + $nl + $entry + $t.Substring($mp.Index + $mp.Length)

  Copy-Item -LiteralPath $File -Destination "$File.bak" -Force
  $t = Renumber $t
  [System.IO.File]::WriteAllText($File, $t, (New-Object System.Text.UTF8Encoding($false)))
  Write-Host ("已新增页面 [$Id]，位置：$After 之后；原文件备份为 " + [IO.Path]::GetFileName($File) + ".bak")
  Write-Host ('下一步：刷新浏览器，再在 HTML 里搜索 id="' + $Id + '" 把骨架文字替换掉。')
  & powershell -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath check -File $File
  return
}

# ---------- check（体检） ----------
$pageIds = Get-PageIds $t
$secs = Get-Sections $t
$secIds = @($secs | ForEach-Object { $_.Groups['id'].Value })
Write-Host "页面注册表： $($secIds.Count) 个 section ｜ $($pageIds.Count) 条 PAGES"
$onlySec = $secIds | Where-Object { $pageIds -cnotcontains $_ }
$onlyPg  = $pageIds | Where-Object { $secIds  -cnotcontains $_ }
if ($onlySec) { Write-Host "  [!] 有页面但未注册进 PAGES： $($onlySec -join ', ')" -ForegroundColor Yellow }
if ($onlyPg)  { Write-Host "  [!] PAGES 里有但页面不存在：  $($onlyPg -join ', ')" -ForegroundColor Yellow }
if (-not $onlySec -and -not $onlyPg) { Write-Host '  [OK] section 与 PAGES 一一对应' -ForegroundColor Green }
$orderBad = $false
for ($i = 0; $i -lt [Math]::Min($secIds.Count, $pageIds.Count); $i++) { if ($secIds[$i] -cne $pageIds[$i]) { $orderBad = $true } }
if ($orderBad -or ($secIds.Count -ne $pageIds.Count)) { Write-Host '  [!] section 顺序与 PAGES 顺序不一致（页码/导航按 PAGES 走）' -ForegroundColor Yellow }
Write-Host ''
Write-Host '  #  id            标题                       眉标  待填'
for ($i = 0; $i -lt $secs.Count; $i = $i + 1) {
  $s = $secs[$i].Value; $id = $secs[$i].Groups['id'].Value
  $tt = [regex]::Match($s, '(?s)<h2 class="slide-title">(?<x>.*?)</h2>').Groups['x'].Value
  if (-not $tt) { $tt = [regex]::Match($s, 'class="cover-title">(?<x>[^<]+)').Groups['x'].Value }
  $tt = ($tt -replace '<[^>]+>', '')
  if ($tt.Length -gt 20) { $tt = $tt.Substring(0, 20) + [char]0x2026 }
  $no = [regex]::Match($s, '<span class="no">(\d+)<').Groups[1].Value
  if (-not $no) { $no = '-' }
  $todo = ([regex]::Matches($s, ([char]0x2026 + '+|' + [char]0xFF08 + '待'))).Count
  $mark = if ($todo -gt 0) { "$todo " + [char]0x5904 } else { [char]0x221A }
  Write-Host ("  {0,-2} {1,-13} {2,-24} {3,-4} {4}" -f ($i + 1), $id, $tt, $no, $mark)
}
$expect = 1; $bad = 0
for ($i = 0; $i -lt $secs.Count; $i = $i + 1) {
  if ($secs[$i].Groups['cls'].Value -match 'cover') { continue }
  $no = [regex]::Match($secs[$i].Value, '<span class="no">(\d+)<').Groups[1].Value
  if ($no -ne ('{0:D2}' -f $expect)) { $bad = $bad + 1; Write-Host "  [!] $($secs[$i].Groups['id'].Value) 眉标号为 $no，应为 $(('{0:D2}' -f $expect))" -ForegroundColor Yellow }
  $expect = $expect + 1
}
if ($bad -eq 0) { Write-Host '  [OK] 眉标序号连续正确' -ForegroundColor Green }
$ph = ([regex]::Matches($t, ([char]0x2026 + '+|' + [char]0xFF08 + '待'))).Count
Write-Host ''
if ($ph -gt 0) { Write-Host ('总计待填占位： ' + $ph + ' 处') }
