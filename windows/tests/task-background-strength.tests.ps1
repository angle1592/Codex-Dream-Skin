[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Root)

$ErrorActionPreference = 'Stop'
. (Join-Path $Root 'scripts\config-utf8.ps1')
. (Join-Path $Root 'scripts\common-windows.ps1')
. (Join-Path $Root 'scripts\theme-windows.ps1')

$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
  'codex-dream-skin-strength-' + $PID + '-' + [guid]::NewGuid().ToString('N')
)
$stateRoot = Join-Path $temporaryRoot 'state'
$active = Join-Path $stateRoot 'active-theme'
$saved = Join-Path $stateRoot 'themes\theme-one'

try {
  New-Item -ItemType Directory -Force -Path $active, $saved | Out-Null
  $imageBytes = [Convert]::FromBase64String(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Wl2n4sAAAAASUVORK5CYII='
  )
  [System.IO.File]::WriteAllBytes((Join-Path $active 'background.png'), $imageBytes)
  [System.IO.File]::WriteAllBytes((Join-Path $saved 'background.png'), $imageBytes)
  $theme = [pscustomobject]@{
    schemaVersion = 1
    id = 'theme-one'
    name = '主题一'
    image = 'background.png'
    appearance = 'auto'
    art = [pscustomobject]@{ safeArea = 'auto'; taskMode = 'auto' }
  }
  Write-DreamSkinTheme -ThemeDirectory $active -Theme $theme
  Write-DreamSkinTheme -ThemeDirectory $saved -Theme (
    $theme | ConvertTo-Json -Depth 8 | ConvertFrom-Json
  )

  $initial = Get-DreamSkinTaskBackgroundStrengthState -StateRoot $stateRoot
  if ($initial.Strength -ne 55 -or $initial.FieldExists) {
    throw 'Legacy themes must default to strength 55 without inventing a persisted field.'
  }
  $preview = Set-DreamSkinTaskBackgroundStrength -Strength 72 `
    -ExpectedThemeId $initial.ThemeId -ExpectedThemeHash $initial.ContentHash -StateRoot $stateRoot
  if ($preview.Strength -ne 72) { throw 'Preview did not update the active theme strength.' }
  $savedAfterPreview = Read-DreamSkinTheme -ThemeDirectory $saved -SkipImageMetadata
  if ($savedAfterPreview.Theme.art.PSObject.Properties['taskBackgroundStrength']) {
    throw 'Preview must not update the saved theme before confirmation.'
  }
  $confirmed = Set-DreamSkinTaskBackgroundStrength -Strength 72 `
    -ExpectedThemeId $preview.ThemeId -ExpectedThemeHash $preview.ContentHash `
    -SyncSavedTheme -StateRoot $stateRoot
  $savedAfterConfirm = Read-DreamSkinTheme -ThemeDirectory $saved -SkipImageMetadata
  if ($confirmed.Strength -ne 72 -or
    (Get-DreamSkinTaskBackgroundStrength -Theme $savedAfterConfirm.Theme) -ne 72) {
    throw 'Confirmation did not persist strength to the matching saved theme.'
  }

  $beforeCancel = Get-DreamSkinTaskBackgroundStrengthState -StateRoot $stateRoot
  $previewCancel = Set-DreamSkinTaskBackgroundStrength -Strength 20 `
    -ExpectedThemeId $beforeCancel.ThemeId -ExpectedThemeHash $beforeCancel.ContentHash `
    -StateRoot $stateRoot
  $restored = Restore-DreamSkinTaskBackgroundStrength -OriginalState $beforeCancel `
    -ExpectedThemeHash $previewCancel.ContentHash -StateRoot $stateRoot
  if ($restored.Strength -ne 72) { throw 'Cancel did not restore the exact previous value.' }

  $activeTheme = Read-DreamSkinTheme -ThemeDirectory $active -SkipImageMetadata
  $activeTheme.Theme.art | Add-Member -NotePropertyName taskBackgroundStrength -NotePropertyValue 'invalid' -Force
  Write-DreamSkinTheme -ThemeDirectory $active -Theme $activeTheme.Theme
  $node = Get-DreamSkinNodeRuntime
  $payload = Invoke-DreamSkinNative -FilePath $node.Path -ArgumentList @(
    (Join-Path $Root 'scripts\injector.mjs'), '--check-payload', '--theme-dir', $active
  )
  if ($payload.ExitCode -ne 0) { throw 'Legacy invalid strength caused payload validation to fail.' }
  $payloadJson = ($payload.Output -join "`n") | ConvertFrom-Json
  if ($payloadJson.art.taskBackgroundStrength -ne 55) {
    throw 'Legacy invalid strength did not fall back to 55 in the managed payload.'
  }

  $dialogSource = Read-DreamSkinUtf8File -Path (Join-Path $Root 'scripts\task-strength-dialog.ps1')
  foreach ($required in @(
      'System.Windows.Forms.TrackBar',
      'Interval = 200',
      'Get-DreamSkinTaskBackgroundStrengthState',
      'Set-DreamSkinTaskBackgroundStrength',
      'Restore-DreamSkinTaskBackgroundStrength',
      '-SyncSavedTheme'
    )) {
    if (-not $dialogSource.Contains($required)) { throw "Task-strength dialog is missing: $required" }
  }

  $traySource = Read-DreamSkinUtf8File -Path (Join-Path $Root 'scripts\tray-dream-skin.ps1')
  foreach ($required in @(
      '任务页背景强度…',
      'task-strength-dialog.ps1',
      '$savedStateIsRunning = $stateIsRunning',
      'Start-DreamSkinPowerShell -Script $startScript'
    )) {
    if (-not $traySource.Contains($required)) { throw "Tray integration is missing: $required" }
  }

  Write-Host 'PASS: per-theme task background strength and stopped-session recovery.'
} finally {
  Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -ErrorAction SilentlyContinue
}