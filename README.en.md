# Codex Dream Skin — Personal Windows Downstream

[中文](./README.md) · [Upstream](https://github.com/Fei-Away/Codex-Dream-Skin) · [Windows guide](./windows/README.en.md)

This repository is a personal Windows-focused downstream of [`Fei-Away/Codex-Dream-Skin`](https://github.com/Fei-Away/Codex-Dream-Skin), currently synchronized with upstream **v1.5.6**. It is maintained for a custom workflow and is not intended for an upstream pull request. It is not affiliated with OpenAI.

## Downstream differences

- One `Codex 梦境皮肤` shortcut launches/reapplies the skin and ensures the tray manager is running.
- Full restore remains inside the tray menu; separate restore and tray shortcuts are unnecessary.
- Each saved theme stores its own Codex task/conversation background strength from 0 to 100.
- The slider previews after roughly 200 ms; OK persists the value and Cancel restores the exact previous value.
- Task strength affects Codex task/conversation routes only. Home screens are unchanged.
- Switching a saved theme automatically restarts a stopped skin session.
- Upstream v1.5.6 content fingerprinting, ZIP validation, Safe CSS checks, hot switching, and rollback remain intact.

## Requirements

- Windows 10/11 x64.
- The official Microsoft Store `OpenAI.Codex` / ChatGPT desktop package, launched at least once.
- Exit Codex and the Dream Skin tray before installing or updating.
- Node.js 22+ for source installation; Node.js 22 is used in the current verification.

## Install from this repository

This personal repository does not currently publish its own release binaries. Use the source installer; upstream Setup binaries do not include the downstream task-strength feature.

```powershell
git clone https://github.com/angle1592/Codex-Dream-Skin.git
cd .\Codex-Dream-Skin
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

Launch **Codex 梦境皮肤**, then right-click the `Codex Dream Skin` tray icon to change backgrounds, import ZIP themes, save/switch themes, adjust task-page strength, pause, update, or fully restore Codex.

Strength meanings: `0` prioritizes readability and hides the task background, `55` is the default balance, and `100` shows the artwork most clearly while retaining a minimum text-protection veil. Values are stored as `art.taskBackgroundStrength` in each theme.

## Update

Exit Codex and the tray, then run:

```powershell
git pull --ff-only
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

The managed runtime under `%LOCALAPPDATA%\CodexDreamSkin\engine` is replaced, while active/saved themes and imported images are preserved.

## Verify

```powershell
node .\tools\sync-runtime-assets.mjs
powershell.exe -NoProfile -File .\windows\tests\run-tests.ps1
```

Logs live under `%LOCALAPPDATA%\CodexDreamSkin`. Do not take ownership of WindowsApps or modify the official app package when troubleshooting.

## Credits and license

Based on upstream [`Fei-Away/Codex-Dream-Skin`](https://github.com/Fei-Away/Codex-Dream-Skin) v1.5.6. The repository remains under its MIT License and NOTICE. Verify the rights for any Wallpaper Engine, character, or third-party artwork you use; local wallpapers are not uploaded by this project.