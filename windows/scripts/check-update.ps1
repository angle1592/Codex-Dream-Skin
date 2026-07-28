[CmdletBinding()]
param(
  [switch]$Json,
  [switch]$Interactive
)

$ErrorActionPreference = 'Stop'
$engineRoot = Split-Path -Parent $PSScriptRoot
$versionPath = Join-Path $engineRoot 'VERSION'
$repository = 'Fei-Away/Codex-Dream-Skin'
$releasePage = "https://github.com/$repository/releases/latest"

function ConvertTo-DreamSkinVersion {
  param([Parameter(Mandatory = $true)][string]$Value)
  $normalized = $Value.Trim()
  if ($normalized.StartsWith('v', [System.StringComparison]::OrdinalIgnoreCase)) {
    $normalized = $normalized.Substring(1)
  }
  if ($normalized -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') {
    throw "Invalid release version: $Value"
  }
  $parsed = $null
  if (-not [version]::TryParse($normalized, [ref]$parsed)) {
    throw "Invalid release version: $Value"
  }
  return $parsed
}

function Show-DreamSkinUpdateResult {
  param([Parameter(Mandatory = $true)][object]$Result)
  Add-Type -AssemblyName System.Windows.Forms
  if ($Result.updateAvailable) {
    $choice = [System.Windows.Forms.MessageBox]::Show(
      "上游 Codex Dream Skin $($Result.latestVersion) 已发布。`r`n`r`n个人版请从自己的仓库更新源码；直接安装上游版本会失去个人功能。是否打开上游发布页？",
      'Codex 梦境皮肤 · 上游更新',
      [System.Windows.Forms.MessageBoxButtons]::YesNo,
      [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
      Start-Process -FilePath $Result.releaseUrl | Out-Null
    }
    return
  }
  [void][System.Windows.Forms.MessageBox]::Show(
    "当前基于的上游版本 $($Result.currentVersion) 已是最新。`r`n个人分支是否有更新，请查看自己的仓库。",
    'Codex 梦境皮肤 · 上游更新',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    [System.Windows.Forms.MessageBoxIcon]::Information
  )
}

try {
  if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
    throw "Installed version file is missing: $versionPath"
  }
  $currentText = ([System.IO.File]::ReadAllText($versionPath)).Trim()
  $current = ConvertTo-DreamSkinVersion -Value $currentText
  $headers = @{ Accept = 'application/vnd.github+json'; 'User-Agent' = 'CodexDreamSkin' }
  $previousProtocol = [Net.ServicePointManager]::SecurityProtocol
  try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/releases/latest" `
      -Headers $headers -Method Get -TimeoutSec 12
  } finally {
    [Net.ServicePointManager]::SecurityProtocol = $previousProtocol
  }
  if (-not $release.tag_name) { throw 'GitHub did not return a release tag.' }
  $latest = ConvertTo-DreamSkinVersion -Value "$($release.tag_name)"
  $result = [pscustomobject]@{
    currentVersion = "v$currentText"
    latestVersion = "v$($latest.ToString())"
    updateAvailable = $latest -gt $current
    releaseUrl = $releasePage
  }
  if ($Json) { $result | ConvertTo-Json -Compress }
  if ($Interactive) { Show-DreamSkinUpdateResult -Result $result }
  if (-not $Json -and -not $Interactive) {
    Write-Host "$($result.currentVersion) -> $($result.latestVersion); update=$($result.updateAvailable)"
  }
} catch {
  if ($Json) {
    [pscustomobject]@{ error = $_.Exception.Message; releaseUrl = $releasePage } | ConvertTo-Json -Compress
  }
  if ($Interactive) {
    Add-Type -AssemblyName System.Windows.Forms
    [void][System.Windows.Forms.MessageBox]::Show(
      "Could not check for updates.`r`n`r`n$($_.Exception.Message)",
      'Codex 梦境皮肤 · 上游更新',
      [System.Windows.Forms.MessageBoxButtons]::OK,
      [System.Windows.Forms.MessageBoxIcon]::Warning
    )
  }
  if (-not $Json -and -not $Interactive) { throw }
  exit 1
}
