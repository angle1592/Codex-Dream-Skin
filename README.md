# Codex Dream Skin — Windows 自定义版

<p align="center">
  <strong>中文</strong> · <a href="./README.en.md">English</a>
</p>

> 这是 [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) 的个人下游定制版，主要面向 Windows Codex 桌面应用。<br>
> 本仓库独立维护这些定制功能，不计划向上游仓库提交合并请求；需要原版时请直接使用上游仓库。

Codex Dream Skin 通过只监听本机回环地址的 CDP 会话，把自定义背景和透明界面注入官方 Codex Windows 应用。侧栏、任务内容、项目选择和输入框仍是原生可交互控件；它不修改 WindowsApps、<code>app.asar</code>、官方二进制或应用签名。

非 OpenAI 官方产品，也不是上游仓库的官方发行版。

## 本仓库的定位

| 项目 | 说明 |
|------|------|
| 上游项目 | [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) |
| 本仓库 | Windows 使用体验优先的个人定制版 |
| 默认分支 | <code>main</code>，保存可直接安装的定制版本 |
| 合并策略 | 不向上游提 PR；需要时选择性同步上游修复 |
| 问题反馈 | 只在[本仓库 Issues](https://github.com/angle1592/Codex-Dream-Skin/issues)反馈本定制版问题 |

<code>macos/</code> 目录仍保留上游实现，但本定制版新增功能和实机验证以 Windows 为主。macOS 用户建议优先参考上游说明。

## 相比所基于的上游版本，本版增加了什么

- **一个快捷方式完成启动和管理**：桌面只保留 <code>Codex 梦境皮肤</code>，它会启动/重新应用皮肤，并确保主题管理托盘运行。
- **主题切换自动恢复**：Codex 更新导致注入会话停止后，选择已保存主题会自动启动恢复流程并提示重启，不再要求手动点第二次“应用”。
- **管理与恢复集中到托盘**：切图、保存主题、切换主题、重新应用、暂停和完全恢复都在同一个右键菜单中。
- **每个主题单独保存任务页强度**：0–100 调节 Codex 任务/对话页面的背景可见度，切回主题时自动恢复该主题自己的数值。
- **实时预览强度**：拖动滑块约 200 毫秒后更新当前任务页；确定保存，取消或关闭窗口恢复原值。
- **修复任务页过亮**：强度值会完整传入注入载荷，并生成浏览器可解析的遮罩颜色，避免首页正常而任务页遮罩失效。
- **减少重复图片**：新版本按 SHA-256 复用相同图片内容；不会继续为重复导入或切换创建相同副本。
- **安全更新与恢复**：运行时安装到用户目录，更新时保留当前主题、已保存主题和导入图片，并可一键恢复官方外观。

## 使用要求

- 可安装并运行 Microsoft Store 官方 Codex 的 Windows 系统。
- 从 Microsoft Store 安装、并注册到当前 Windows 用户的官方 <code>OpenAI.Codex</code> 应用。
- Node.js 22 或更高版本，<code>node.exe</code> 必须可从 <code>PATH</code> 找到。
- Windows PowerShell 5.1 或更高版本。
- 安装或更新前必须完全退出 Codex，并右击托盘图标选择“退出托盘”。
- 普通使用不需要管理员权限，也不要接管 WindowsApps 目录权限。

安装前可先检查：

~~~powershell
node --version
Get-AppxPackage -Name OpenAI.Codex
~~~

## 安装

### 方式一：Git

~~~powershell
git clone https://github.com/angle1592/Codex-Dream-Skin.git
cd .\Codex-Dream-Skin\windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
~~~

### 方式二：下载 ZIP

从本仓库下载 ZIP 并解压，打开解压后的 <code>windows</code> 文件夹，在地址栏输入 <code>powershell</code>，然后运行：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
~~~

安装器会：

1. 校验官方 Codex Store 包和 Node.js。
2. 备份可恢复的外观配置。
3. 把受管运行时安装到 <code>%LOCALAPPDATA%\CodexDreamSkin\engine</code>。
4. 初始化当前主题、已保存主题和图片归档。
5. 在桌面和开始菜单创建唯一的 <code>Codex 梦境皮肤</code> 快捷方式。

安装命令里的 <code>Bypass</code> 只作用于这一次安装进程；日常快捷方式使用 <code>RemoteSigned</code>。

## 日常使用

需要皮肤时，双击桌面的 **Codex 梦境皮肤**。不要先用普通 Codex 快捷方式启动；如果 Codex 已经打开，Dream Skin 会询问是否重启到皮肤会话。

启动后右击系统托盘里的 Codex Dream Skin 图标：

| 菜单 | 用途 |
|------|------|
| 应用或重新应用 | 重新注入当前主题 |
| 暂停皮肤 | 暂时显示官方外观 |
| 更换背景图 | 导入 PNG、JPEG 或 WebP 纯背景 |
| 任务页背景强度… | 调整当前主题的任务/对话页面背景 |
| 保存当前主题 | 输入名称并保存当前图片和强度 |
| 已保存主题 | 切换回以前保存的主题 |
| 打开图片文件夹 | 查看导入图片归档，不是主题列表 |
| 完全恢复 Codex | 关闭 Dream Skin 并恢复官方外观 |
| 退出托盘 | 退出管理器，安装/更新前必须执行 |

## 新增并保存一个主题

1. 双击 <code>Codex 梦境皮肤</code>。
2. 右击托盘图标，选择“更换背景图”。
3. 选择一张纯背景图片。不要导入带 Codex 窗口、文字、按钮或输入框的效果截图。
4. 选择“任务页背景强度…”，调到合适数值。
5. 选择“保存当前主题”，输入名称，例如“初音”。
6. 以后从“已保存主题 → 初音”切回，图片和任务页强度会一起恢复。

只把图片放进图片文件夹不会自动创建主题；必须执行“保存当前主题”，它才会出现在主题列表。

图片限制：

- 文件格式：PNG、JPEG 或 WebP。
- 文件大小不超过 16 MB。
- 单边不超过 16384 像素。
- 总像素不超过 5000 万。

相同内容的新图片会被复用。旧版本留下的重复文件不会自动删除，以免误删用户素材。

## 任务页背景强度

这个选项只影响 **Codex 任务/对话页面**，不改变 Codex 首页或 ChatGPT 首页。

- <code>0</code>：任务页背景隐藏，遮罩最深。
- <code>55</code>：默认平衡效果。
- <code>100</code>：背景最清晰，仍保留最低文字保护层。
- 数值越小，任务页越暗；数值越大，图片越明显。

实时预览要求 Codex 是通过 <code>Codex 梦境皮肤</code> 启动的，并且皮肤会话仍在运行。如果提示实时预览不可用，仍可保存数值；下次“应用或重新应用”或重新启动皮肤时生效。

每个主题独立保存自己的强度。“确定”保存；“取消”、Esc 或关闭窗口恢复打开对话框前的数值。

## 更新本定制版

1. 右击托盘图标，选择“退出托盘”。
2. 完全关闭 Codex。
3. 更新仓库并重新安装：

~~~powershell
cd .\Codex-Dream-Skin
git pull origin main
cd .\windows
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-dream-skin.ps1
~~~

重新安装会替换受管运行时并重建快捷方式，不会删除当前主题、已保存主题或导入图片。

## 恢复官方外观

推荐直接使用托盘里的“完全恢复 Codex”。

也可以在 <code>windows</code> 目录运行：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -PromptRestart
~~~

同时移除 Dream Skin 快捷方式：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\restore-dream-skin.ps1 -RestoreBaseTheme -PromptRestart -Uninstall
~~~

## 文件和日志

| 用途 | 路径 |
|------|------|
| 状态根目录 | <code>%LOCALAPPDATA%\CodexDreamSkin</code> |
| 当前主题 | <code>%LOCALAPPDATA%\CodexDreamSkin\active-theme</code> |
| 已保存主题 | <code>%LOCALAPPDATA%\CodexDreamSkin\themes</code> |
| 导入图片归档 | <code>%LOCALAPPDATA%\CodexDreamSkin\images</code> |
| 注入器日志 | <code>%LOCALAPPDATA%\CodexDreamSkin\injector.log</code> |
| 注入器错误日志 | <code>%LOCALAPPDATA%\CodexDreamSkin\injector-error.log</code> |
| 验证日志 | <code>%LOCALAPPDATA%\CodexDreamSkin\verify.log</code> |

更详细的 Windows 使用与排错说明见 [windows/README.md](./windows/README.md)。

## 验证与开发

运行完整 Windows 测试：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\tests\run-tests.ps1
~~~

启动皮肤后生成验证截图：

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\scripts\verify-dream-skin.ps1 -ScreenshotPath "$env:TEMP\codex-dream-skin.png"
~~~

## 安全边界与已知限制

- CDP 只绑定 <code>127.0.0.1</code>；皮肤运行时不要运行来路不明的本机程序。
- 不修改官方 Codex 安装目录、WindowsApps、<code>app.asar</code> 或签名。
- 不写入 API Key、Base URL 或模型供应商设置。
- Codex 桌面应用更新后，页面结构可能变化；皮肤失效时先更新本仓库并重新运行安装器。
- 主题背景和人物素材由使用者自行提供；公开分发前请确认版权、肖像和商标授权。

## 上游同步策略

本仓库把 <code>origin/main</code> 作为可安装的个人定制版，不向上游创建 PR。维护时保留上游远程：

~~~powershell
git remote add upstream https://github.com/Fei-Away/Codex-Dream-Skin.git
git fetch upstream
~~~

上游更新只在完成冲突检查和 Windows 回归测试后选择性同步，避免覆盖本版的一体化托盘和逐主题强度功能。

## 许可与署名

本项目基于 [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin)，遵循仓库中现有许可证与声明。Codex、OpenAI 及相关商标和产品权利归各自权利人。
