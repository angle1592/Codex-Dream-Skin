[CmdletBinding()]
param([int]$Port = 9335)

$ErrorActionPreference = 'Stop'
$PortExplicit = $PSBoundParameters.ContainsKey('Port')
$startScript = Join-Path $PSScriptRoot 'start-dream-skin.ps1'
$trayScript = Join-Path $PSScriptRoot 'tray-dream-skin.ps1'
$powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
$stateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'
$logPath = Join-Path $stateRoot 'start-launch-error.log'

. (Join-Path $PSScriptRoot 'common-windows.ps1')

try {
  Assert-DreamSkinPort -Port $Port
  if ($PortExplicit) {
    & $startScript -Port $Port -PromptRestart
  } else {
    & $startScript -PromptRestart
  }
  if (-not (Test-DreamSkinTrayActive)) {
    $trayPort = $Port
    try {
      $trayState = Read-DreamSkinState -Path (Join-Path $stateRoot 'state.json')
      if ([int]$trayState.port -ge 1024 -and [int]$trayState.port -le 65535) { $trayPort = [int]$trayState.port }
    } catch {}
    $trayToken = ConvertTo-DreamSkinProcessArgument -Value $trayScript
    $trayArguments = '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File ' +
      $trayToken + " -Port $trayPort"
    Start-Process -FilePath $powershell -ArgumentList $trayArguments -WindowStyle Hidden | Out-Null
  }
  if (Test-Path -LiteralPath $logPath -PathType Leaf) {
    Remove-Item -LiteralPath $logPath -Force
  }
} catch {
  $launchError = $_
  $details = @(
    "Time: $([DateTime]::Now.ToString('o'))"
    "Message: $($launchError.Exception.Message)"
    "Category: $($launchError.CategoryInfo)"
    "Stack: $($launchError.ScriptStackTrace)"
  ) -join "`r`n"

  try {
    Write-DreamSkinUtf8FileAtomically -Path $logPath -Content ($details + "`r`n")
  } catch {
    # Keep the original launch error as the user-facing failure.
  }

  $shell = New-Object -ComObject WScript.Shell
  $message = "Codex 梦境皮肤启动失败。`r`n`r`n$($launchError.Exception.Message)`r`n`r`nLog: $logPath"
  $null = $shell.Popup($message, 0, 'Codex 梦境皮肤', 16)
  exit 1
}
