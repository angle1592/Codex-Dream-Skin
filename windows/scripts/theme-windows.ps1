if (-not (Get-Command Read-DreamSkinUtf8File -ErrorAction SilentlyContinue)) {
  . (Join-Path $PSScriptRoot 'config-utf8.ps1')
}

$script:DreamSkinMaxImageBytes = 16 * 1024 * 1024
function Get-DreamSkinTaskBackgroundStrength {
  param([AllowNull()][object]$Theme)
  $defaultStrength = 55
  if ($null -eq $Theme) { return $defaultStrength }
  $artProperty = $Theme.PSObject.Properties['art']
  if ($null -eq $artProperty -or $null -eq $artProperty.Value) { return $defaultStrength }
  $strengthProperty = $artProperty.Value.PSObject.Properties['taskBackgroundStrength']
  if ($null -eq $strengthProperty -or $null -eq $strengthProperty.Value) { return $defaultStrength }
  $value = $strengthProperty.Value
  $numericTypes = @(
    [System.TypeCode]::Byte, [System.TypeCode]::SByte,
    [System.TypeCode]::Int16, [System.TypeCode]::UInt16,
    [System.TypeCode]::Int32, [System.TypeCode]::UInt32,
    [System.TypeCode]::Int64, [System.TypeCode]::UInt64,
    [System.TypeCode]::Single, [System.TypeCode]::Double, [System.TypeCode]::Decimal
  )
  if ([System.Type]::GetTypeCode($value.GetType()) -notin $numericTypes) { return $defaultStrength }
  $number = [double]$value
  if ([double]::IsNaN($number) -or [double]::IsInfinity($number) -or
    $number -ne [Math]::Floor($number) -or $number -lt 0 -or $number -gt 100) {
    return $defaultStrength
  }
  return [int]$number
}

function Assert-DreamSkinNoReparseComponents {
  param([Parameter(Mandatory = $true)][string]$Path)
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $root = [System.IO.Path]::GetPathRoot($fullPath)
  $current = $fullPath
  while ($true) {
    if (Test-Path -LiteralPath $current) {
      $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
      if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Managed Dream Skin path contains a junction or symbolic link: $current"
      }
    }
    $currentNormalized = $current.TrimEnd('\')
    $rootNormalized = $root.TrimEnd('\')
    if ($currentNormalized.Equals($rootNormalized, [System.StringComparison]::OrdinalIgnoreCase)) { break }
    $parent = [System.IO.Path]::GetDirectoryName($current)
    if (-not $parent -or $parent.Equals($current, [System.StringComparison]::OrdinalIgnoreCase)) { break }
    $current = $parent
  }
}

function Ensure-DreamSkinManagedDirectory {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Root
  )
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
  if (-not ($fullPath.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
      $fullPath.StartsWith($fullRoot + '\', [System.StringComparison]::OrdinalIgnoreCase))) {
    throw "Managed Dream Skin path escaped its state root: $fullPath"
  }
  Assert-DreamSkinNoReparseComponents -Path $fullPath
  if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
    throw "Managed Dream Skin path is a file, not a directory: $fullPath"
  }
  New-Item -ItemType Directory -Force -Path $fullPath | Out-Null
  Assert-DreamSkinNoReparseComponents -Path $fullPath
  if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
    throw "Managed Dream Skin directory could not be created: $fullPath"
  }
}

function Get-DreamSkinValidatedImageMetadata {
  param([Parameter(Mandatory = $true)][string]$Path)
  if (-not (Get-Command Get-DreamSkinNodeRuntime -ErrorAction SilentlyContinue)) {
    throw 'Node.js runtime validation is unavailable for image metadata checks.'
  }
  $node = Get-DreamSkinNodeRuntime
  $metadataScript = Join-Path $PSScriptRoot 'image-metadata.mjs'
  $output = @(& $node.Path $metadataScript '--check' ([System.IO.Path]::GetFullPath($Path)) 2>&1)
  if ($LASTEXITCODE -ne 0) {
    throw "Image metadata is invalid or exceeds the 16384px / 50MP safety limit: $Path"
  }
  try { $metadata = ($output -join "`n") | ConvertFrom-Json -ErrorAction Stop } catch {
    throw "Image metadata helper returned invalid output: $Path"
  }
  if ($null -eq $metadata -or $null -eq $metadata.width -or $null -eq $metadata.height) {
    throw "Image metadata is invalid or exceeds the 16384px / 50MP safety limit: $Path"
  }
}

function Assert-DreamSkinImageFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$SkipImageMetadata
  )
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
    throw "Image does not exist: $fullPath"
  }
  $extension = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
  if ($extension -notin @('.png', '.jpg', '.jpeg', '.webp')) {
    throw "Unsupported image format: $extension"
  }
  $length = (Get-Item -LiteralPath $fullPath -Force).Length
  if ($length -lt 1) { throw 'Theme image cannot be empty.' }
  if ($length -gt $script:DreamSkinMaxImageBytes) {
    throw 'Theme image exceeds the 16 MB limit.'
  }
  if (-not $SkipImageMetadata) {
    Get-DreamSkinValidatedImageMetadata -Path $fullPath
  }
}

function Get-DreamSkinThemePaths {
  param([string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'))
  $fullRoot = [System.IO.Path]::GetFullPath($StateRoot)
  return [pscustomobject]@{
    Root = $fullRoot
    Active = Join-Path $fullRoot 'active-theme'
    Saved = Join-Path $fullRoot 'themes'
    Images = Join-Path $fullRoot 'images'
    PauseFile = Join-Path $fullRoot 'paused'
    State = Join-Path $fullRoot 'state.json'
  }
}

function Test-DreamSkinThemePathWithin {
  param([string]$Path, [string]$Root)
  if (-not $Path -or -not $Root) { return $false }
  try {
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $fullRoot = [System.IO.Path]::GetFullPath($Root).TrimEnd('\')
    $inside = $fullPath.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase) -or
      $fullPath.StartsWith($fullRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)
    if (-not $inside) { return $false }

    $current = $fullPath.TrimEnd('\')
    while ($true) {
      if (-not (Test-Path -LiteralPath $current)) { return $false }
      $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
      if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        return $false
      }
      if ($current.Equals($fullRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $true
      }
      $parent = [System.IO.Path]::GetDirectoryName($current)
      if (-not $parent -or $parent.Equals($current, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $false
      }
      $current = $parent.TrimEnd('\')
    }
  } catch {
    return $false
  }
}

function Read-DreamSkinTheme {
  param(
    [Parameter(Mandatory = $true)][string]$ThemeDirectory,
    [switch]$SkipImageMetadata
  )
  $directory = [System.IO.Path]::GetFullPath($ThemeDirectory)
  Assert-DreamSkinNoReparseComponents -Path $directory
  $themePath = Join-Path $directory 'theme.json'
  Assert-DreamSkinNoReparseComponents -Path $themePath
  if (-not (Test-Path -LiteralPath $themePath -PathType Leaf)) {
    throw "Theme metadata is missing: $themePath"
  }
  try {
    $theme = (Read-DreamSkinUtf8File -Path $themePath) | ConvertFrom-Json -ErrorAction Stop
  } catch {
    throw "Theme metadata is invalid JSON: $themePath"
  }
  if ($null -eq $theme -or $theme -is [string] -or $theme -is [array] -or -not $theme.image) {
    throw "Theme metadata must be an object with a relative image path: $themePath"
  }
  $image = "$($theme.image)"
  if ([System.IO.Path]::IsPathRooted($image)) { throw 'Theme image path must be relative.' }
  $imagePath = [System.IO.Path]::GetFullPath((Join-Path $directory $image))
  if (-not (Test-DreamSkinThemePathWithin -Path $imagePath -Root $directory) -or
    -not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
    throw 'Theme image must remain inside its theme directory and exist.'
  }
  Assert-DreamSkinImageFile -Path $imagePath -SkipImageMetadata:$SkipImageMetadata
  return [pscustomobject]@{
    Directory = $directory
    ThemePath = $themePath
    ImagePath = $imagePath
    Theme = $theme
  }
}

function Write-DreamSkinTheme {
  param(
    [Parameter(Mandatory = $true)][string]$ThemeDirectory,
    [Parameter(Mandatory = $true)][object]$Theme
  )
  Assert-DreamSkinNoReparseComponents -Path $ThemeDirectory
  New-Item -ItemType Directory -Force -Path $ThemeDirectory | Out-Null
  Assert-DreamSkinNoReparseComponents -Path $ThemeDirectory
  $json = $Theme | ConvertTo-Json -Depth 8
  $themePath = Join-Path $ThemeDirectory 'theme.json'
  Assert-DreamSkinNoReparseComponents -Path $themePath
  Write-DreamSkinUtf8FileAtomically -Path $themePath -Content ($json + "`r`n")
}
function Test-DreamSkinJsonObject {
  param([AllowNull()][object]$Value)
  return ($null -ne $Value -and ($Value -is [pscustomobject] -or $Value -is [hashtable]))
}

function Set-DreamSkinTaskBackgroundStrengthValue {
  param(
    [Parameter(Mandatory = $true)][object]$Theme,
    [Parameter(Mandatory = $true)][int]$Strength
  )
  $artProperty = $Theme.PSObject.Properties['art']
  if ($null -eq $artProperty -or -not (Test-DreamSkinJsonObject -Value $artProperty.Value)) {
    $art = [pscustomobject]@{}
    $Theme | Add-Member -NotePropertyName art -NotePropertyValue $art -Force
  } else {
    $art = $artProperty.Value
  }
  $art | Add-Member -NotePropertyName taskBackgroundStrength -NotePropertyValue $Strength -Force
  return $Theme
}

function Get-DreamSkinTaskBackgroundStrengthState {
  param([string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'))
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  $active = Read-DreamSkinTheme -ThemeDirectory $paths.Active -SkipImageMetadata
  $artProperty = $active.Theme.PSObject.Properties['art']
  $artExists = $null -ne $artProperty
  $artWasObject = $artExists -and (Test-DreamSkinJsonObject -Value $artProperty.Value)
  $fieldProperty = if ($artWasObject) {
    $artProperty.Value.PSObject.Properties['taskBackgroundStrength']
  } else { $null }
  $fieldExists = $null -ne $fieldProperty
  return [pscustomobject]@{
    ThemeId = "$($active.Theme.id)"
    ThemeName = if ($active.Theme.name) { "$($active.Theme.name)" } else { "$($active.Theme.id)" }
    ThemePath = $active.ThemePath
    Strength = Get-DreamSkinTaskBackgroundStrength -Theme $active.Theme
    ContentHash = (Get-FileHash -LiteralPath $active.ThemePath -Algorithm SHA256).Hash
    ArtExists = $artExists
    ArtWasObject = $artWasObject
    RawArtValue = if ($artExists -and -not $artWasObject) { $artProperty.Value } else { $null }
    FieldExists = $fieldExists
    RawValue = if ($fieldExists) { $fieldProperty.Value } else { $null }
  }
}

function Assert-DreamSkinTaskBackgroundStrengthSession {
  param(
    [Parameter(Mandatory = $true)][object]$State,
    [Parameter(Mandatory = $true)][string]$ExpectedThemeId,
    [Parameter(Mandatory = $true)][string]$ExpectedThemeHash
  )
  if ($State.ThemeId -cne $ExpectedThemeId) {
    throw 'The active theme changed while task background strength was open. Reopen the setting.'
  }
  if ($State.ContentHash -cne $ExpectedThemeHash) {
    throw 'The active theme was modified elsewhere. The newer theme was not overwritten.'
  }
}

function Set-DreamSkinTaskBackgroundStrength {
  param(
    [Parameter(Mandatory = $true)][double]$Strength,
    [Parameter(Mandatory = $true)][string]$ExpectedThemeId,
    [Parameter(Mandatory = $true)][string]$ExpectedThemeHash,
    [switch]$SyncSavedTheme,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  if ([double]::IsNaN($Strength) -or [double]::IsInfinity($Strength)) {
    throw 'Task background strength must be a finite number.'
  }
  $resolvedStrength = [int][Math]::Min(100, [Math]::Max(0, [Math]::Floor($Strength + 0.5)))
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  $state = Get-DreamSkinTaskBackgroundStrengthState -StateRoot $StateRoot
  Assert-DreamSkinTaskBackgroundStrengthSession -State $state -ExpectedThemeId $ExpectedThemeId `
    -ExpectedThemeHash $ExpectedThemeHash

  $savedTheme = $null
  if ($SyncSavedTheme) {
    $matches = @(Get-DreamSkinSavedThemes -StateRoot $StateRoot -SkipImageMetadata |
      Where-Object { $_.Id -ceq $ExpectedThemeId })
    if ($matches.Count -gt 1) {
      throw 'Multiple saved themes use the active theme ID. No theme was synchronized.'
    }
    if ($matches.Count -eq 1) {
      $savedTheme = Read-DreamSkinTheme -ThemeDirectory $matches[0].Path -SkipImageMetadata
    }
  }

  $active = Read-DreamSkinTheme -ThemeDirectory $paths.Active -SkipImageMetadata
  $updatedActiveTheme = Set-DreamSkinTaskBackgroundStrengthValue -Theme $active.Theme -Strength $resolvedStrength
  Write-DreamSkinTheme -ThemeDirectory $paths.Active -Theme $updatedActiveTheme
  if ($null -ne $savedTheme) {
    $updatedSavedTheme = Set-DreamSkinTaskBackgroundStrengthValue -Theme $savedTheme.Theme -Strength $resolvedStrength
    Write-DreamSkinTheme -ThemeDirectory $savedTheme.Directory -Theme $updatedSavedTheme
  }
  return Get-DreamSkinTaskBackgroundStrengthState -StateRoot $StateRoot
}

function Restore-DreamSkinTaskBackgroundStrength {
  param(
    [Parameter(Mandatory = $true)][object]$OriginalState,
    [Parameter(Mandatory = $true)][string]$ExpectedThemeHash,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  $currentState = Get-DreamSkinTaskBackgroundStrengthState -StateRoot $StateRoot
  Assert-DreamSkinTaskBackgroundStrengthSession -State $currentState `
    -ExpectedThemeId "$($OriginalState.ThemeId)" -ExpectedThemeHash $ExpectedThemeHash
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  $active = Read-DreamSkinTheme -ThemeDirectory $paths.Active -SkipImageMetadata
  $theme = $active.Theme

  if (-not $OriginalState.ArtExists) {
    $theme.PSObject.Properties.Remove('art')
  } elseif (-not $OriginalState.ArtWasObject) {
    $theme | Add-Member -NotePropertyName art -NotePropertyValue $OriginalState.RawArtValue -Force
  } else {
    $artProperty = $theme.PSObject.Properties['art']
    if ($null -eq $artProperty -or -not (Test-DreamSkinJsonObject -Value $artProperty.Value)) {
      throw 'The active theme art settings changed while task background strength was open.'
    }
    if ($OriginalState.FieldExists) {
      $artProperty.Value | Add-Member -NotePropertyName taskBackgroundStrength `
        -NotePropertyValue $OriginalState.RawValue -Force
    } else {
      $artProperty.Value.PSObject.Properties.Remove('taskBackgroundStrength')
    }
  }
  Write-DreamSkinTheme -ThemeDirectory $paths.Active -Theme $theme
  return Get-DreamSkinTaskBackgroundStrengthState -StateRoot $StateRoot
}


function Initialize-DreamSkinThemeStore {
  param(
    [Parameter(Mandatory = $true)][string]$SkillRoot,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  foreach ($directory in @($paths.Root, $paths.Active, $paths.Saved, $paths.Images)) {
    Ensure-DreamSkinManagedDirectory -Path $directory -Root $paths.Root
  }
  $assetRoot = Join-Path $SkillRoot 'assets'
  $assetImage = Join-Path $assetRoot 'dream-reference.jpg'
  Assert-DreamSkinImageFile -Path $assetImage
  $activeTheme = Join-Path $paths.Active 'theme.json'
  Assert-DreamSkinNoReparseComponents -Path $activeTheme
  if (-not (Test-Path -LiteralPath $activeTheme -PathType Leaf)) {
    Ensure-DreamSkinManagedDirectory -Path $paths.Active -Root $paths.Root
    Assert-DreamSkinNoReparseComponents -Path (Join-Path $paths.Active 'dream-reference.jpg')
    $activeImage = Join-Path $paths.Active 'dream-reference.jpg'
    Copy-Item -LiteralPath (Join-Path $assetRoot 'dream-reference.jpg') `
      -Destination $activeImage -Force
    Assert-DreamSkinNoReparseComponents -Path $activeImage
    Assert-DreamSkinImageFile -Path $activeImage
    $imageArchive = Join-Path $paths.Images 'dream-reference.jpg'
    Assert-DreamSkinNoReparseComponents -Path $imageArchive
    Copy-Item -LiteralPath (Join-Path $assetRoot 'dream-reference.jpg') `
      -Destination $imageArchive -Force
    Assert-DreamSkinNoReparseComponents -Path $imageArchive
    Assert-DreamSkinImageFile -Path $imageArchive
    Assert-DreamSkinNoReparseComponents -Path $activeTheme
    Copy-Item -LiteralPath (Join-Path $assetRoot 'theme.json') -Destination $activeTheme -Force
  }
  $retiredPresetDirectory = Join-Path $paths.Saved 'preset-romantic-rose'
  Assert-DreamSkinNoReparseComponents -Path $retiredPresetDirectory
  if (Test-Path -LiteralPath $retiredPresetDirectory) {
    Remove-Item -LiteralPath $retiredPresetDirectory -Recurse -Force
  }
  $presetDirectory = Join-Path $paths.Saved 'preset-arina-hashimoto'
  $presetTheme = Join-Path $presetDirectory 'theme.json'
  Assert-DreamSkinNoReparseComponents -Path $presetDirectory
  Assert-DreamSkinNoReparseComponents -Path $presetTheme
  if (-not (Test-Path -LiteralPath $presetTheme -PathType Leaf)) {
    Ensure-DreamSkinManagedDirectory -Path $presetDirectory -Root $paths.Root
    $presetImage = Join-Path $presetDirectory 'dream-reference.jpg'
    Assert-DreamSkinNoReparseComponents -Path $presetImage
    Copy-Item -LiteralPath (Join-Path $assetRoot 'dream-reference.jpg') `
      -Destination $presetImage -Force
    Assert-DreamSkinNoReparseComponents -Path $presetImage
    Assert-DreamSkinImageFile -Path $presetImage
    Assert-DreamSkinNoReparseComponents -Path $presetTheme
    Copy-Item -LiteralPath (Join-Path $assetRoot 'theme.json') -Destination $presetTheme -Force
  }
  $null = Read-DreamSkinTheme -ThemeDirectory $paths.Active
  return $paths
}

function New-DreamSkinThemeImageName {
  param([Parameter(Mandatory = $true)][string]$Extension)
  return 'art-' + (Get-Date).ToString('yyyyMMdd-HHmmss-fff') + '-' +
    [guid]::NewGuid().ToString('N').Substring(0, 8) + $Extension.ToLowerInvariant()
}

function Set-DreamSkinActiveTheme {
  param(
    [Parameter(Mandatory = $true)][string]$ImagePath,
    [AllowNull()][object]$Theme,
    [string]$Name,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  Ensure-DreamSkinManagedDirectory -Path $paths.Root -Root $paths.Root
  Ensure-DreamSkinManagedDirectory -Path $paths.Active -Root $paths.Root
  Ensure-DreamSkinManagedDirectory -Path $paths.Images -Root $paths.Root
  $source = [System.IO.Path]::GetFullPath($ImagePath)
  Assert-DreamSkinImageFile -Path $source
  $extension = [System.IO.Path]::GetExtension($source).ToLowerInvariant()
  $oldImage = $null
  try { $oldImage = (Read-DreamSkinTheme -ThemeDirectory $paths.Active).ImagePath } catch {}
  if ($null -eq $Theme) {
    $Theme = [pscustomobject]@{
      id = 'custom'
      name = '自定义主题'
      appearance = 'auto'
      art = [pscustomobject]@{ focusX = $null; focusY = $null; safeArea = 'auto'; taskMode = 'auto' }
      palette = [pscustomobject]@{}
    }
  }
  $imageName = New-DreamSkinThemeImageName -Extension $extension
  $target = Join-Path $paths.Active $imageName
  $temporary = Join-Path $paths.Active ('.dream-tmp-' + [guid]::NewGuid().ToString('N') + $extension)
  try {
    Assert-DreamSkinNoReparseComponents -Path $target
    Assert-DreamSkinNoReparseComponents -Path $temporary
    Copy-Item -LiteralPath $source -Destination $temporary -Force
    Assert-DreamSkinNoReparseComponents -Path $temporary
    Assert-DreamSkinImageFile -Path $temporary
    Move-Item -LiteralPath $temporary -Destination $target -Force
    Assert-DreamSkinNoReparseComponents -Path $target
    Assert-DreamSkinImageFile -Path $target
    $Theme | Add-Member -NotePropertyName image -NotePropertyValue $imageName -Force
    if ($Name) { $Theme | Add-Member -NotePropertyName name -NotePropertyValue $Name -Force }
    if (-not $Theme.id) { $Theme | Add-Member -NotePropertyName id -NotePropertyValue 'custom' -Force }
    if (-not $Theme.appearance) { $Theme | Add-Member -NotePropertyName appearance -NotePropertyValue 'auto' -Force }
    if (-not $Theme.art) {
      $Theme | Add-Member -NotePropertyName art -NotePropertyValue `
        ([pscustomobject]@{ focusX = $null; focusY = $null; safeArea = 'auto'; taskMode = 'auto' }) -Force
    }
    if (-not $Theme.palette) {
      $Theme | Add-Member -NotePropertyName palette -NotePropertyValue ([pscustomobject]@{}) -Force
    }
    Write-DreamSkinTheme -ThemeDirectory $paths.Active -Theme $Theme
  } finally {
    Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
  }
  $sameImage = $oldImage -and ([System.IO.Path]::GetFullPath($oldImage) -ieq [System.IO.Path]::GetFullPath($target))
  if ($oldImage -and -not $sameImage -and
    (Test-DreamSkinThemePathWithin -Path $oldImage -Root $paths.Active)) {
    Remove-Item -LiteralPath $oldImage -Force -ErrorAction SilentlyContinue
  }
  $targetItem = Get-Item -LiteralPath $target -Force
  $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
  $archiveMatch = $null
  foreach ($candidate in @(Get-ChildItem -LiteralPath $paths.Images -File -ErrorAction SilentlyContinue)) {
    Assert-DreamSkinNoReparseComponents -Path $candidate.FullName
    if ($candidate.Length -eq $targetItem.Length -and
      (Get-FileHash -LiteralPath $candidate.FullName -Algorithm SHA256).Hash -ceq $targetHash) {
      $archiveMatch = $candidate.FullName
      break
    }
  }
  if (-not $archiveMatch) {
    $imageArchive = Join-Path $paths.Images $imageName
    Assert-DreamSkinNoReparseComponents -Path $imageArchive
    Copy-Item -LiteralPath $target -Destination $imageArchive -Force
    Assert-DreamSkinNoReparseComponents -Path $imageArchive
    Assert-DreamSkinImageFile -Path $imageArchive
  }
  return Read-DreamSkinTheme -ThemeDirectory $paths.Active
}

function Save-DreamSkinCurrentTheme {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  $trimmed = $Name.Trim()
  if (-not $trimmed -or $trimmed.Length -gt 80 -or $trimmed -match '[\u0000-\u001f]') {
    throw 'Theme name must be between 1 and 80 visible characters.'
  }
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  Ensure-DreamSkinManagedDirectory -Path $paths.Root -Root $paths.Root
  Ensure-DreamSkinManagedDirectory -Path $paths.Saved -Root $paths.Root
  $active = Read-DreamSkinTheme -ThemeDirectory $paths.Active
  $id = (Get-Date).ToString('yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
  $destination = Join-Path $paths.Saved $id
  Ensure-DreamSkinManagedDirectory -Path $destination -Root $paths.Root
  $extension = [System.IO.Path]::GetExtension($active.ImagePath).ToLowerInvariant()
  $imageName = 'art' + $extension
  $destinationImage = Join-Path $destination $imageName
  Assert-DreamSkinNoReparseComponents -Path $destinationImage
  Copy-Item -LiteralPath $active.ImagePath -Destination $destinationImage -Force
  Assert-DreamSkinNoReparseComponents -Path $destinationImage
  Assert-DreamSkinImageFile -Path $destinationImage
  $theme = $active.Theme | ConvertTo-Json -Depth 8 | ConvertFrom-Json
  $theme.id = $id
  $theme.name = $trimmed
  $theme.image = $imageName
  Write-DreamSkinTheme -ThemeDirectory $destination -Theme $theme
  return Read-DreamSkinTheme -ThemeDirectory $destination
}

function Get-DreamSkinSavedThemes {
  param(
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'),
    [switch]$SkipImageMetadata
  )
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  Ensure-DreamSkinManagedDirectory -Path $paths.Root -Root $paths.Root
  Ensure-DreamSkinManagedDirectory -Path $paths.Saved -Root $paths.Root
  if (-not (Test-Path -LiteralPath $paths.Saved -PathType Container)) { return @() }
  $themes = @()
  foreach ($directory in Get-ChildItem -LiteralPath $paths.Saved -Directory -ErrorAction SilentlyContinue) {
    try {
      $loaded = Read-DreamSkinTheme -ThemeDirectory $directory.FullName -SkipImageMetadata:$SkipImageMetadata
      $themes += [pscustomobject]@{
        Id = "$($loaded.Theme.id)"
        Name = if ($loaded.Theme.name) { "$($loaded.Theme.name)" } else { $directory.Name }
        Path = $directory.FullName
      }
    } catch {}
  }
  return @($themes | Sort-Object Name)
}

function Use-DreamSkinSavedTheme {
  param(
    [Parameter(Mandatory = $true)][string]$ThemeDirectory,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  Ensure-DreamSkinManagedDirectory -Path $paths.Root -Root $paths.Root
  Ensure-DreamSkinManagedDirectory -Path $paths.Saved -Root $paths.Root
  $directory = [System.IO.Path]::GetFullPath($ThemeDirectory)
  if (-not (Test-DreamSkinThemePathWithin -Path $directory -Root $paths.Saved)) {
    throw 'Saved theme must remain inside the Dream Skin themes folder.'
  }
  $saved = Read-DreamSkinTheme -ThemeDirectory $directory
  $theme = $saved.Theme | ConvertTo-Json -Depth 8 | ConvertFrom-Json
  return Set-DreamSkinActiveTheme -ImagePath $saved.ImagePath -Theme $theme -StateRoot $StateRoot
}

function Set-DreamSkinPaused {
  param(
    [Parameter(Mandatory = $true)][bool]$Paused,
    [string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin')
  )
  $paths = Get-DreamSkinThemePaths -StateRoot $StateRoot
  Ensure-DreamSkinManagedDirectory -Path $paths.Root -Root $paths.Root
  if ($Paused) {
    Assert-DreamSkinNoReparseComponents -Path $paths.PauseFile
    Write-DreamSkinUtf8FileAtomically -Path $paths.PauseFile -Content "paused`r`n"
  } else {
    if (Test-Path -LiteralPath $paths.PauseFile) { Assert-DreamSkinNoReparseComponents -Path $paths.PauseFile }
    Remove-Item -LiteralPath $paths.PauseFile -Force -ErrorAction SilentlyContinue
  }
  return $Paused
}

function Test-DreamSkinPaused {
  param([string]$StateRoot = (Join-Path $env:LOCALAPPDATA 'CodexDreamSkin'))
  return (Test-Path -LiteralPath (Get-DreamSkinThemePaths -StateRoot $StateRoot).PauseFile -PathType Leaf)
}
