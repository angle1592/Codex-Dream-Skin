[CmdletBinding()]
param(
  [int]$Port = 9335,
  [switch]$NoShortcuts
)

$ErrorActionPreference = 'Stop'
$PortExplicit = $PSBoundParameters.ContainsKey('Port')
$SkillRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'common-windows.ps1')
. (Join-Path $PSScriptRoot 'theme-windows.ps1')

$operationLock = Enter-DreamSkinOperationLock
try {
  Assert-DreamSkinPort -Port $Port
  $null = Get-DreamSkinNodeRuntime
  $registeredInstalls = @(Get-DreamSkinRegisteredCodexInstalls)
  if ($registeredInstalls.Count -eq 0) {
    throw 'The official OpenAI.Codex Store package is not installed or its identity cannot be validated.'
  }
  foreach ($registeredCodex in $registeredInstalls) {
    if ((Get-DreamSkinCodexProcesses -Codex $registeredCodex).Count -gt 0) {
      throw 'Close Codex before installing Dream Skin so config.toml cannot change during the transaction.'
    }
  }

  $StateRoot = Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'
  $themePaths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  Ensure-DreamSkinManagedDirectory -Path $themePaths.Root -Root $themePaths.Root
  $StatePath = Join-Path $StateRoot 'state.json'
  $existingState = Read-DreamSkinState -Path $StatePath
  $savedPathCandidate = Get-DreamSkinCodexStatePathCandidate -State $existingState
  $savedCodex = Resolve-DreamSkinCodexInstallFromState -State $existingState -RegisteredInstalls $registeredInstalls
  if ($null -ne $savedPathCandidate -and $null -eq $savedCodex -and
    (Get-DreamSkinCodexProcesses -Codex $savedPathCandidate).Count -gt 0) {
    throw 'The saved Codex path is still running but no longer matches a registered Store package. Close it manually before installing.'
  }
  if (Test-DreamSkinTrayActive) {
    throw 'Exit the Codex Dream Skin tray before reinstalling so every shortcut can move to the new runtime safely.'
  }
  $engine = Install-DreamSkinRuntimeEngine -SkillRoot $SkillRoot -StateRoot $StateRoot
  $null = Initialize-DreamSkinThemeStore -SkillRoot $engine.Root -StateRoot $StateRoot
  $ConfigPath = Join-Path $HOME '.codex\config.toml'
  $BackupPath = Join-Path $StateRoot 'config.before-dream-skin.toml'
  Install-DreamSkinBaseTheme -ConfigPath $ConfigPath -BackupPath $BackupPath

  if (-not $NoShortcuts) {
    $shell = New-Object -ComObject WScript.Shell
    $desktop = [Environment]::GetFolderPath('Desktop')
    $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
    $powershell = (Get-Command powershell.exe -ErrorAction Stop).Source
    $wscript = Join-Path $env:SystemRoot 'System32\wscript.exe'
    $startLauncher = Join-Path $engine.Scripts 'launch-start-hidden.vbs'
    $trayScript = $engine.Tray
    $portArgument = if ($PortExplicit) { " -Port $Port" } else { '' }
    $launcherPortArgument = if ($PortExplicit) { " $Port" } else { '' }
    $startShortcutName = 'Codex 梦境皮肤.lnk'
    $legacyShortcutNames = @(
      'Codex Dream Skin.lnk',
      'Codex Dream Skin - Tray.lnk',
      'Codex Dream Skin - Restore.lnk',
      'Codex 梦境皮肤 - 启动.lnk',
      'Codex 梦境皮肤 - 主题管理.lnk',
      'Codex 梦境皮肤 - 恢复官方外观.lnk'
    )

    foreach ($folder in @($desktop, $startMenu)) {
      foreach ($legacyShortcutName in $legacyShortcutNames) {
        Remove-Item -LiteralPath (Join-Path $folder $legacyShortcutName) -Force -ErrorAction SilentlyContinue
      }
      $shortcut = $shell.CreateShortcut((Join-Path $folder $startShortcutName))
      $shortcut.TargetPath = $wscript
      $shortcut.Arguments = "//B //NoLogo `"$startLauncher`"$launcherPortArgument"
      $shortcut.WorkingDirectory = $engine.Root
      $shortcut.Description = 'Launch Codex Dream Skin and its tray theme manager'
      $shortcut.IconLocation = "$powershell,0"
      $shortcut.Save()
    }

    Start-Process -FilePath $powershell -ArgumentList `
      "-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File `"$trayScript`"$portArgument" `
      -WindowStyle Hidden | Out-Null
  }

  if ($NoShortcuts) {
    Write-Host "Codex Dream Skin base theme installed at $($engine.Root). Run $($engine.Start) to launch it."
  } else {
    Write-Host 'Codex Dream Skin installed. One shortcut launches the skin and tray theme manager.'
  }
} finally {
  Exit-DreamSkinOperationLock -Mutex $operationLock
}
