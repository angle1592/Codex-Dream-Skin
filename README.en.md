# Codex Dream Skin — Windows Custom Edition

<p align="center">
  <a href="./README.md">中文</a> · <strong>English</strong>
</p>

> This is a personal downstream customization of [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin), focused on the Windows Codex desktop app.<br>
> These custom features are maintained independently and are not intended to be proposed back to the upstream repository. Use upstream directly when you want the original edition.

Codex Dream Skin injects a custom background and transparent surfaces into the official Codex Windows app through a loopback-only CDP session. The sidebar, task content, project picker, and composer remain native and interactive. It does not modify WindowsApps, <code>app.asar</code>, official binaries, or the app signature.

This is neither an official OpenAI product nor an official upstream release.

## Repository position

| Item | Policy |
|------|--------|
| Upstream | [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) |
| This repository | A personal Windows-first custom edition |
| Default branch | <code>main</code>, kept directly installable |
| Merge policy | No upstream PRs; upstream fixes may be synchronized selectively |
| Bug reports | Report custom-edition issues in [this repository](https://github.com/angle1592/Codex-Dream-Skin/issues) |

The inherited <code>macos/</code> implementation remains in the tree, but this edition's added features and live verification are Windows-first. macOS users should prefer the upstream documentation.

## Differences from the upstream baseline

- **One launcher:** the single <code>Codex 梦境皮肤</code> shortcut launches or reapplies the skin and ensures that the tray manager is running.
- **Self-healing theme switches:** if a Codex update stops the injector session, choosing a saved theme automatically starts recovery and prompts for restart instead of requiring a second Apply action.
- **One management surface:** image import, saved themes, reapply, pause, and full restore all live in the tray menu.
- **Per-theme task strength:** each theme stores its own 0–100 background strength for Codex task/conversation routes.
- **Live preview:** slider changes preview after about 200 ms; OK saves and Cancel restores the previous value.
- **Task-route brightness fix:** strength survives injector payload normalization and produces valid browser color values instead of losing the readability overlay.
- **Content-addressed images:** identical imported images are reused by SHA-256 instead of being archived repeatedly.
- **Recoverable updates:** the managed runtime can be replaced without deleting active, saved, or imported themes.

## Requirements

- A Windows system supported by the official Microsoft Store Codex app.
- The official <code>OpenAI.Codex</code> app installed from Microsoft Store and registered for the current Windows user.
- Node.js 22 or newer, with <code>node.exe</code> available on <code>PATH</code>.
- Windows PowerShell 5.1 or newer.
- Fully exit Codex and choose **退出托盘** before installation or update.
- Normal operation does not require administrator rights or WindowsApps ownership changes.

Preflight checks:

~~~powershell
node --version
Get-AppxPackage -Name OpenAI.Codex
~~~

## Install

~~~powershell
git clone https://github.com/angle1592/Codex-Dream-Skin.git
cd .\Codex-Dream-Skin\windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
~~~

You may also download and extract the repository ZIP, open PowerShell in its <code>windows</code> directory, and run the same installer command.

The installer validates Codex and Node.js, saves a recoverable appearance baseline, installs the managed runtime under <code>%LOCALAPPDATA%\CodexDreamSkin\engine</code>, initializes the local theme store, and creates one desktop/Start-menu shortcut:

- <code>Codex 梦境皮肤</code>

The install-time <code>Bypass</code> applies only to this explicit installer process. Daily shortcuts use <code>RemoteSigned</code>.

## Daily use

Double-click **Codex 梦境皮肤** whenever you want the skin. Do not launch stock Codex first; if Codex is already open, the custom launcher asks before restarting it into a skin-enabled session.

Right-click the Codex Dream Skin tray icon:

| Menu item | Purpose |
|-----------|---------|
| 应用或重新应用 | Reinject the active theme |
| 暂停皮肤 | Temporarily show the stock appearance |
| 更换背景图 | Import a UI-free PNG, JPEG, or WebP |
| 任务页背景强度… | Adjust the current theme's task/conversation background |
| 保存当前主题 | Save the active image and strength under a name |
| 已保存主题 | Switch to a previously saved theme |
| 打开图片文件夹 | Open the image archive, not the theme list |
| 完全恢复 Codex | Stop Dream Skin and restore the stock appearance |
| 退出托盘 | Exit the manager before install or update |

## Create and save a theme

1. Launch <code>Codex 梦境皮肤</code>.
2. Right-click the tray icon and choose **更换背景图**.
3. Select a UI-free wallpaper, not a screenshot containing Codex windows, text, buttons, or a composer.
4. Open **任务页背景强度…** and choose the desired value.
5. Choose **保存当前主题** and enter a name.
6. Later, select that name under **已保存主题**; its image and task strength return together.

Copying an image into the image archive does not create a theme. You must choose **保存当前主题** before it appears under **已保存主题**.

Imported images must be PNG, JPEG, or WebP; no larger than 16 MB, 16384 pixels on either side, or 50 million total pixels.

## Task background strength

This setting affects **Codex task/conversation routes only**, not the Codex or ChatGPT home route.

- <code>0</code>: hides the task background with the darkest overlay.
- <code>55</code>: balanced default.
- <code>100</code>: clearest background with a minimum readability layer.
- Lower values are darker; higher values reveal more of the image.

Live preview requires a skin session launched through <code>Codex 梦境皮肤</code>. If preview is unavailable, the value can still be saved and will take effect after reapply or the next skin launch. Each saved theme owns an independent value.

## Update

Exit the tray, fully close Codex, then:

~~~powershell
cd .\Codex-Dream-Skin
git pull origin main
cd .\windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
~~~

Reinstallation replaces the managed runtime and rebuilds the shortcut without deleting active, saved, or imported themes.

## Restore stock Codex

Use **完全恢复 Codex** in the tray, or run from the <code>windows</code> directory:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -PromptRestart
~~~

Add <code>-Uninstall</code> to also remove Dream Skin shortcuts.

## Files and logs

| Purpose | Path |
|---------|------|
| State root | <code>%LOCALAPPDATA%\CodexDreamSkin</code> |
| Active theme | <code>%LOCALAPPDATA%\CodexDreamSkin\active-theme</code> |
| Saved themes | <code>%LOCALAPPDATA%\CodexDreamSkin\themes</code> |
| Imported images | <code>%LOCALAPPDATA%\CodexDreamSkin\images</code> |
| Injector log | <code>%LOCALAPPDATA%\CodexDreamSkin\injector.log</code> |
| Injector error log | <code>%LOCALAPPDATA%\CodexDreamSkin\injector-error.log</code> |
| Verification log | <code>%LOCALAPPDATA%\CodexDreamSkin\verify.log</code> |

See [windows/README.en.md](./windows/README.en.md) for deeper usage and troubleshooting.

## Validation

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1
~~~

After launching the skin:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\scripts\verify-dream-skin.ps1 -ScreenshotPath "$env:TEMP\codex-dream-skin.png"
~~~

## Security and limitations

- CDP binds only to <code>127.0.0.1</code>; avoid untrusted local software while the skin is active.
- The tool does not modify WindowsApps, <code>app.asar</code>, official binaries, or signatures.
- It does not write API keys, Base URLs, or model-provider settings.
- Codex updates may change renderer structure. Update this repository and rerun the installer if the skin stops applying.
- Users supply their own theme images and are responsible for copyright, likeness, and trademark permissions before redistribution.

## Upstream synchronization

This repository treats <code>origin/main</code> as the installable custom edition and does not open upstream PRs. Maintainers may retain the upstream remote:

~~~powershell
git remote add upstream https://github.com/Fei-Away/Codex-Dream-Skin.git
git fetch upstream
~~~

Upstream changes should be synchronized selectively only after conflict review and the full Windows regression suite.

## License and attribution

This project is derived from [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) and follows the licenses and notices already present in the repository. Codex, OpenAI, and related marks and product rights belong to their respective owners.
