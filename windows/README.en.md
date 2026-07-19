# Codex Dream Skin for Windows

<p align="center">
  <a href="./README.md">中文</a> · <strong>English</strong>
</p>

Codex Dream Skin loads an external theme into the official Codex Windows desktop app through loopback CDP. The native sidebar, project picker, task content, and composer remain interactive. The tool does not modify WindowsApps, `app.asar`, or the app signature.

## Requirements

- The official `OpenAI.Codex` app installed from Microsoft Store and registered for the current user.
- Node.js 22 or newer, with `node.exe` available on `PATH`.
- Windows PowerShell 5.1 or newer.

Run the installer after Codex has fully exited. Normal use does not require administrator access or ownership changes under WindowsApps.

## Install

Open PowerShell in the repository's `windows` directory and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
```

The installer validates the official Codex Store package and Node.js, saves a recoverable appearance baseline, and initializes the local theme store. By default it creates one shortcut:

- `Codex 梦境皮肤`: launch or reapply the skin and ensure the tray theme manager is running.

Theme switching, task-page strength, and **完全恢复 Codex** all live in the tray menu, so separate theme-manager and restore shortcuts are no longer needed. Updating removes only the legacy split shortcuts created by Dream Skin.

`Bypass` in the install command applies only to that user-initiated installer process. The installer verifies the runtime copy with SHA-256, then clears download-zone markers only from managed PowerShell copies under `%LOCALAPPDATA%\CodexDreamSkin\engine`. Daily shortcuts use `RemoteSigned` and do not override system or enterprise Group Policy.

Pass `-Port` during installation to use a fixed custom port. Valid ports range from `1024` through `65535`.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1 -Port 9444
```

## Update

Exit the Dream Skin tray and close Codex, update the checkout (`git pull`, or download the latest source again), then rerun the install command above. The installer atomically replaces the managed runtime and rebuilds its shortcuts without deleting the active theme, saved themes, or imported images.

## Launch and verify

The single `Codex 梦境皮肤` shortcut is the recommended launcher. It asks for confirmation before restarting an open Codex window and ensures the tray manager is running after launch. The normal Codex shortcut still opens the stock appearance, but it does not establish Dream Skin's local CDP session.

Command-line launch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\start-dream-skin.ps1 -PromptRestart
```

Run verification after launch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-dream-skin.ps1 `
  -ScreenshotPath "$env:TEMP\codex-dream-skin.png"
```

The verification script confirms:

- The CDP endpoint is bound to loopback and belongs to the current official Codex package.
- The current renderer has loaded the expected skin version.
- The native sidebar and composer remain present.
- The decorative skin layer does not intercept pointer events.
- When the current route is home, the themed home structure has loaded.

Next, use the generated screenshot to check horizontal overflow and text contrast. On both the home and normal task routes, manually check the project menu and composer interaction. See [`references/qa-inventory.md`](./references/qa-inventory.md) for the complete visual checklist.

## Change and save themes

Double-click `Codex 梦境皮肤`, then right-click its system-tray icon to:

- Import a PNG, JPEG, or WebP background.
- Save the active theme and switch through saved themes.
- Adjust the current theme's Codex task/conversation background with `任务页背景强度…`.
- Pause or resume the skin.
- Reapply the theme or fully restore Codex.

Import a UI-free wallpaper rather than a preview containing a window, sidebar, composer, text, or buttons. Images may be at most 16 MB, 16384 pixels on either side, and 50 million total pixels.

Task background strength ranges from 0 through 100: `0` hides the task background, `55` preserves the default look, and `100` is clearest while retaining a minimal readability layer. Dragging previews after roughly 200 ms; **OK** saves to the current theme and **Cancel** restores the state from when the dialog opened. Every saved theme keeps its own value. This setting affects only Codex task/conversation routes, not the Codex or ChatGPT home route.

`打开图片文件夹` opens the imported-image archive, not the saved-theme list. Use `保存当前主题` before a theme appears under `已保存主题`. The current version reuses identical image content by SHA-256, so reimporting or repeatedly switching a theme no longer creates new identical copies. Updating does not automatically delete files left by older versions.

## Restore and remove shortcuts

Restore the stock appearance. If Codex is running, confirm its closure and relaunch:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\restore-dream-skin.ps1 `
  -RestoreBaseTheme -PromptRestart
```

Add `-Uninstall` to also remove the shortcuts created by Dream Skin:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\restore-dream-skin.ps1 `
  -RestoreBaseTheme -PromptRestart -Uninstall
```

`-RecoverConfigBackup` restores the complete pre-install `config.toml` backup and saves the current configuration first. Reserve it for a damaged configuration that normal `-RestoreBaseTheme` recovery cannot resolve.

## Files and logs

| Purpose | Path |
|---------|------|
| Dream Skin state root | `%LOCALAPPDATA%\CodexDreamSkin` |
| Active theme | `%LOCALAPPDATA%\CodexDreamSkin\active-theme` |
| Saved themes | `%LOCALAPPDATA%\CodexDreamSkin\themes` |
| Imported image archive | `%LOCALAPPDATA%\CodexDreamSkin\images` |
| Session state | `%LOCALAPPDATA%\CodexDreamSkin\state.json` |
| Injector log | `%LOCALAPPDATA%\CodexDreamSkin\injector.log` |
| Injector error log | `%LOCALAPPDATA%\CodexDreamSkin\injector-error.log` |
| Verification log | `%LOCALAPPDATA%\CodexDreamSkin\verify.log` |
| Codex configuration | `%USERPROFILE%\.codex\config.toml` |

See [`../docs/platforms.md`](../docs/platforms.md) for the complete platform path reference.

## Troubleshooting

### Node.js is missing

Run `node --version`, confirm that it reports version 22 or newer, and reopen PowerShell so an updated `PATH` takes effect.

### The official Codex package is missing

Run:

```powershell
Get-AppxPackage -Name OpenAI.Codex
```

The scripts accept only a registered official Store package. They do not launch Codex from an arbitrary executable path.

### The installer asks you to close Codex

Close every Codex window and run the installer again. Installation requires stable app and configuration state.

### Antivirus reports the old tray shortcut

Older tray shortcuts combined hidden PowerShell with `ExecutionPolicy Bypass`, which can trigger behavior-based LNK detections. Do not whitelist the detection blindly. Update the source and rerun the installer so the shortcuts use `RemoteSigned`. If the updated shortcut is still detected, leave it quarantined and report the antivirus product, version, detection name, and shortcut properties without sharing secrets or private data.

### The port is occupied

When `-Port` is omitted, the launcher searches for a free port beginning at `9335`. If another process owns an explicitly requested port, choose a different port rather than stopping an unknown listener.

### Verification cannot find a CDP endpoint

Launch Codex through `Codex 梦境皮肤`, then run verification. A normal Codex launch does not open the debug session used by Dream Skin.

### The skin stops working after a Codex update

Run the installer and launch shortcut again. The scripts rediscover the currently registered Store package instead of trusting an executable path from an older app version.

### The image folder contains many duplicates

Older versions archived a newly named image on every import or saved-theme switch even when the bytes were identical. The current version compares SHA-256 and archives identical content only once. Install and update intentionally leave existing copies untouched to avoid deleting user files.

Open this custom repository's [new issue page](https://github.com/angle1592/Codex-Dream-Skin/issues/new/choose) and choose the bug form when reporting a problem. Include the Windows version, Codex source, reproduction steps, and relevant log lines. Remove secrets, `auth.json`, relay tokens, and private conversation content.

## Security boundaries

- CDP binds only to `127.0.0.1`. Avoid untrusted local software while the skin is active.
- The tool does not modify the official Codex installation, WindowsApps, `app.asar`, or signatures.
- It does not write API keys, Base URLs, or model provider settings.
- Restore controls only Codex processes that pass package identity, executable path, and recorded session checks.

Maintainer and agent constraints live in [`SKILL.md`](./SKILL.md). See [`references/runtime-notes.md`](./references/runtime-notes.md) for deeper runtime troubleshooting.
