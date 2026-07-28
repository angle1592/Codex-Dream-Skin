# Personal Windows Downstream Guide

Back to the [repository README](../README.en.md) · [中文](./README.md) · [upstream Windows guide](https://github.com/Fei-Away/Codex-Dream-Skin/blob/main/windows/README.en.md)

This Windows-focused downstream is based on upstream v1.5.6. It adds one launch/management shortcut, per-theme task-page strength, and automatic recovery when a saved theme is selected after the watcher stopped.

## Requirements and install

Use Windows 10/11 x64, the official Microsoft Store `OpenAI.Codex` package, and Node.js 22+. Exit Codex and the tray before installing or updating.

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

The source installer validates the Store package and Node runtime, preserves the original appearance config, installs a managed runtime under `%LOCALAPPDATA%\CodexDreamSkin\engine`, removes the retired three-shortcut layout, creates one **Codex 梦境皮肤** shortcut, and launches the tray manager.

The shortcut launches/reapplies the skin and ensures the tray is present. Change backgrounds, import ZIPs, save/switch themes, pause, update, and fully restore from the tray.

## Per-theme task strength

Open **任务页背景强度…**. `0` hides the task background, `55` is the default balance, and `100` shows the artwork most clearly. Preview is debounced by roughly 200 ms. OK persists `art.taskBackgroundStrength` to the matching saved theme; Cancel restores only the original field.

This affects Codex task/conversation routes only, not the Codex or ChatGPT home screen. Missing or invalid legacy values render as 55; official imported packages must contain an integer from 0 through 100.

## Update, verify, restore

```powershell
git pull --ff-only
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\verify-dream-skin.ps1
```

Logs are under `%LOCALAPPDATA%\CodexDreamSkin`. Use **完全恢复 Codex** in the tray to restore the stock appearance. Never take ownership of WindowsApps or replace official package files.