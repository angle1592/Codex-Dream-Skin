# Codex Dream Skin — Windows 个人定制分支

[English](./README.en.md) · [上游项目](https://github.com/Fei-Away/Codex-Dream-Skin) · [Windows 详细说明](./windows/README.md)

这是 [`Fei-Away/Codex-Dream-Skin`](https://github.com/Fei-Away/Codex-Dream-Skin) 的个人 Windows 定制分支，当前基于上游 **v1.5.6**。它用于维护我自己的使用方式，不准备向上游提交 PR，也不代表 OpenAI 或上游项目。

本仓库保留上游的本机 CDP 注入、安全校验、主题 ZIP、主题去重、热切换与恢复机制；不会修改 WindowsApps、`app.asar` 或官方 Codex 二进制文件。

## 与上游的区别

| 功能 | 本分支 | 上游 v1.5.6 |
|---|---:|---:|
| Windows 单一快捷方式，同时启动皮肤与主题管理 | ✅ | 部分入口分开 |
| 恢复官方外观集成在托盘菜单 | ✅ | ✅ |
| 每个主题单独保存“任务页背景强度” | ✅ | ❌ |
| 0–100 滑块，约 200 ms 实时预览 | ✅ | ❌ |
| 只调整 Codex 任务/对话页，首页不变 | ✅ | ❌ |
| 会话停止时切换已保存主题会自动恢复皮肤 | ✅ | ❌ |
| 按内容指纹识别重复主题/图片 | ✅（继承上游） | ✅ |
| 官方主题 ZIP 与 Safe CSS 安全校验 | ✅（继承上游） | ✅ |

个人功能主要针对 Windows；macOS 文件保留上游兼容与共享运行时同步，但不是本分支的主要测试环境。

## 使用要求

- Windows 10/11 x64。
- Microsoft Store 安装的官方 `OpenAI.Codex` / ChatGPT 桌面应用，至少启动过一次。
- 安装或更新时必须先退出 Codex，并从托盘菜单选择“退出托盘”。
- 源码安装需要 Node.js 22 或更高版本；当前机器已使用 Node.js 22 验证。
- 皮肤依赖只监听 `127.0.0.1` 的本机 CDP 会话。运行期间不要执行不可信的本机程序。

## 安装

本个人仓库目前不发布独立 Release。请从源码安装，不要下载上游 Setup.exe 后期待出现本分支的任务页强度功能。

```powershell
git clone https://github.com/angle1592/Codex-Dream-Skin.git
cd .\Codex-Dream-Skin
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

安装成功后，桌面和开始菜单只保留一个用途入口：

- **Codex 梦境皮肤**：启动或重新应用皮肤，同时确保主题管理托盘运行。

“完全恢复 Codex”“暂停皮肤”“更换背景图”“保存当前主题”等操作都在托盘菜单里，不需要额外恢复或主题管理快捷方式。

## 日常使用

1. 双击 **Codex 梦境皮肤**。
2. 第一次启用或 Codex 已经普通启动时，按提示允许重启。
3. 在系统托盘右键 `Codex Dream Skin` 图标打开管理菜单。
4. 换背景：选择“更换背景图”。
5. 要让它出现在“已保存主题”中，再选择“保存当前主题”并输入名称。
6. 以后从“已保存主题”直接切换；若注入进程已经停止，本分支会自动重新启动皮肤流程。

支持 PNG、JPG/JPEG 和 WebP。请导入纯背景图，不要把包含 Codex 界面的截图当作背景。

### 每主题任务页背景强度

托盘选择 **任务页背景强度…**：

- `0`：任务/对话页几乎完全遮住背景，优先可读性。
- `55`：默认值，兼顾背景与文字。
- `100`：背景最清晰，仍保留最低限度的文字保护层。

拖动滑块约 200 ms 后实时预览；“确定”保存到当前主题，“取消”恢复打开窗口前的值。该值写入 `theme.json` 的 `art.taskBackgroundStrength`，每个已保存主题各自独立。它只影响 Codex 任务/对话页面，不修改 Codex 首页或 ChatGPT 首页。

### 恢复官方外观

托盘选择 **完全恢复 Codex**。它会移除实时注入、恢复安装前保存的外观配置并退出托盘；已保存主题和图片默认保留，便于以后重新安装。

## 更新本分支

先退出 Codex 和托盘，然后：

```powershell
git pull --ff-only
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

更新会替换 `%LOCALAPPDATA%\CodexDreamSkin\engine` 的受管运行时，但保留 `%LOCALAPPDATA%\CodexDreamSkin\themes`、活动主题和导入图片。

本分支同步上游时采用“先合并上游稳定版本，再重新验证个人扩展”的方式；不会向上游仓库合并。

## 日志与排错

状态与日志位于 `%LOCALAPPDATA%\CodexDreamSkin`，常用文件包括：

- `state.json`：当前 CDP、Codex 包与注入器进程记录。
- `injector-error.log`：注入器错误。
- `verify.log`：渲染与窗口验证结果。
- `start-launch-error.log`：统一快捷方式启动失败详情。

Codex 更新后皮肤失效时，先退出托盘和 Codex，再重新运行安装命令。不要接管 WindowsApps 所有权，也不要手工替换官方包文件。

## 开发与验证

```powershell
node .\tools\sync-runtime-assets.mjs
powershell.exe -NoProfile -File .\windows\tests\run-tests.ps1
```

共享 `runtime/` 是 CSS、渲染器与主题包校验器的主源；修改后必须运行同步工具，再提交生成的 Windows/macOS 资产。

## 上游、许可与声明

- 上游项目：[`Fei-Away/Codex-Dream-Skin`](https://github.com/Fei-Away/Codex-Dream-Skin)
- 当前同步基线：上游 v1.5.6
- 许可：沿用仓库中的 MIT License 与 NOTICE
- 非 OpenAI 官方产品；Codex、ChatGPT 及相关商标属于各自权利人。
- 使用 Wallpaper Engine、人物或其他素材时，请自行确认个人使用与再分发权限；本仓库不会上传你的本地壁纸。