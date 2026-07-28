[CmdletBinding()]
param(
  [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'),
  [switch]$SkinRunning
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
. (Join-Path $PSScriptRoot 'theme-windows.ps1')

$originalState = Get-DreamSkinTaskBackgroundStrengthState -StateRoot $StateRoot
$session = @{
  Latest = $originalState
  PreviewApplied = $false
  Confirmed = $false
  Invalid = $false
}

$form = [System.Windows.Forms.Form]::new()
$form.Text = 'Codex 梦境皮肤 - 任务页背景强度'
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ClientSize = [System.Drawing.Size]::new(470, 205)
$form.Font = [System.Drawing.Font]::new('Microsoft YaHei UI', 9)

$title = [System.Windows.Forms.Label]::new()
$title.Text = 'Codex 任务/对话页面的背景强度'
$title.AutoSize = $true
$title.Location = [System.Drawing.Point]::new(22, 20)
$form.Controls.Add($title)

$themeLabel = [System.Windows.Forms.Label]::new()
$themeLabel.Text = "当前主题：$($originalState.ThemeName)"
$themeLabel.AutoSize = $true
$themeLabel.ForeColor = [System.Drawing.Color]::DimGray
$themeLabel.Location = [System.Drawing.Point]::new(22, 48)
$form.Controls.Add($themeLabel)

$slider = [System.Windows.Forms.TrackBar]::new()
$slider.Minimum = 0
$slider.Maximum = 100
$slider.TickFrequency = 10
$slider.SmallChange = 1
$slider.LargeChange = 10
$slider.Value = [int]$originalState.Strength
$slider.Location = [System.Drawing.Point]::new(18, 78)
$slider.Size = [System.Drawing.Size]::new(380, 45)
$form.Controls.Add($slider)

$valueLabel = [System.Windows.Forms.Label]::new()
$valueLabel.Text = "$($slider.Value)%"
$valueLabel.AutoSize = $true
$valueLabel.Location = [System.Drawing.Point]::new(405, 84)
$form.Controls.Add($valueLabel)

$hint = [System.Windows.Forms.Label]::new()
$hint.Text = if ($SkinRunning) {
  '拖动后会实时预览；确定保存，取消恢复原值。'
} else {
  '实时预览不可用；保存后将在下次应用主题时生效。'
}
$hint.AutoSize = $true
$hint.ForeColor = if ($SkinRunning) { [System.Drawing.Color]::DimGray } else { [System.Drawing.Color]::DarkOrange }
$hint.Location = [System.Drawing.Point]::new(22, 126)
$form.Controls.Add($hint)

$okButton = [System.Windows.Forms.Button]::new()
$okButton.Text = '确定'
$okButton.Size = [System.Drawing.Size]::new(82, 30)
$okButton.Location = [System.Drawing.Point]::new(276, 160)
$form.Controls.Add($okButton)

$cancelButton = [System.Windows.Forms.Button]::new()
$cancelButton.Text = '取消'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$cancelButton.Size = [System.Drawing.Size]::new(82, 30)
$cancelButton.Location = [System.Drawing.Point]::new(368, 160)
$form.Controls.Add($cancelButton)
$form.AcceptButton = $okButton
$form.CancelButton = $cancelButton

$previewTimer = [System.Windows.Forms.Timer]::new()
$previewTimer.Interval = 200

function Show-DreamSkinStrengthMessage {
  param(
    [Parameter(Mandatory = $true)][string]$Message,
    [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Warning
  )
  [void][System.Windows.Forms.MessageBox]::Show(
    $form,
    $Message,
    'Codex 梦境皮肤',
    [System.Windows.Forms.MessageBoxButtons]::OK,
    $Icon
  )
}

function Disable-DreamSkinStrengthSession {
  param([Parameter(Mandatory = $true)][string]$Message)
  $session.Invalid = $true
  $previewTimer.Stop()
  $slider.Enabled = $false
  $okButton.Enabled = $false
  Show-DreamSkinStrengthMessage -Message $Message
}

$previewTimer.add_Tick({
  $previewTimer.Stop()
  if ($session.Invalid) { return }
  try {
    $session.Latest = Set-DreamSkinTaskBackgroundStrength -Strength $slider.Value `
      -ExpectedThemeId $originalState.ThemeId -ExpectedThemeHash $session.Latest.ContentHash `
      -StateRoot $StateRoot
    $session.PreviewApplied = $true
  } catch {
    Disable-DreamSkinStrengthSession -Message $_.Exception.Message
  }
})

$slider.add_ValueChanged({
  $valueLabel.Text = "$($slider.Value)%"
  if (-not $session.Invalid) {
    $previewTimer.Stop()
    $previewTimer.Start()
  }
})

$okButton.add_Click({
  if ($session.Invalid) { return }
  $previewTimer.Stop()
  try {
    $session.Latest = Set-DreamSkinTaskBackgroundStrength -Strength $slider.Value `
      -ExpectedThemeId $originalState.ThemeId -ExpectedThemeHash $session.Latest.ContentHash `
      -SyncSavedTheme -StateRoot $StateRoot
    $session.PreviewApplied = $true
    $session.Confirmed = $true
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Close()
  } catch {
    Disable-DreamSkinStrengthSession -Message $_.Exception.Message
  }
})

$form.add_FormClosing({
  $previewTimer.Stop()
  if ($session.Confirmed -or -not $session.PreviewApplied) { return }
  try {
    $session.Latest = Restore-DreamSkinTaskBackgroundStrength -OriginalState $originalState `
      -ExpectedThemeHash $session.Latest.ContentHash -StateRoot $StateRoot
  } catch {
    Show-DreamSkinStrengthMessage -Message (
      "未覆盖新的主题设置。`r`n`r`n" + $_.Exception.Message
    )
  }
})

try {
  [void]$form.ShowDialog()
} finally {
  $previewTimer.Dispose()
  $form.Dispose()
}
