# Windows 个人定制版使用说明

返回[仓库首页](../README.md) · [English](./README.en.md) · [上游 Windows 文档](https://github.com/Fei-Away/Codex-Dream-Skin/blob/main/windows/README.md)

这里说明个人分支的 Windows 用法。当前代码基于上游 v1.5.11，并增加单一入口、每主题任务页背景强度和停止会话自动恢复。它不是 OpenAI 或上游官方版本。

兼容基线包含 Codex 26.727 新版主页面与设置页选择器。若状态显示运行但任务页仍无皮肤，先确认已安装本分支 v1.5.11 运行时，而不是只恢复旧快捷方式。

## 要求

- Windows 10/11 x64。
- Microsoft Store 的官方 `OpenAI.Codex` 包。
- Node.js 22+（源码安装）。
- 安装、更新或恢复前先关闭 Codex；重新安装前还要从托盘选择“退出托盘”。

不要修改 WindowsApps 权限、替换官方文件或将调试端口暴露到局域网。

## 安装命令

在仓库根目录执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

安装器会：

- 校验已注册的官方 Store 包与 Node.js；
- 备份 Codex 外观配置；
- 安装受管运行时到 `%LOCALAPPDATA%\CodexDreamSkin\engine`；
- 清理旧版三个桌面快捷方式；
- 在桌面和开始菜单创建唯一的 **Codex 梦境皮肤** 快捷方式；
- 启动系统托盘主题管理。

快捷方式会运行 `launch-start-dream-skin.ps1`，先启动或重新应用皮肤，再确保托盘管理器存在。恢复功能已在托盘的“完全恢复 Codex”中，不需要独立恢复快捷方式。

## 托盘菜单

| 菜单 | 用途 |
|---|---|
| 应用或重新应用 | 启动/修复当前皮肤会话 |
| 暂停皮肤 / 继续显示皮肤 | 实时移除或恢复注入 |
| 更换背景图 | 选择本地 PNG、JPG/JPEG、WebP |
| 任务页背景强度… | 调整当前主题的 Codex 任务/对话页背景 |
| 导入主题 ZIP… | 安全校验后加入主题库，不立即切换 |
| 保存当前主题 | 为当前背景与参数创建可切换主题 |
| 已保存主题 | 热切换主题；会话停止时自动启动恢复流程 |
| 检查更新… | 检查上游 Release；个人分支仍应通过 Git 更新源码 |
| 完全恢复 Codex | 恢复官方外观并退出托盘 |

### 任务页背景强度

范围 `0–100`，默认 `55`：

- `0`：任务页遮罩最强，背景基本隐藏。
- `55`：默认平衡。
- `100`：背景最清晰。

滑块约 200 ms 后实时预览。“确定”将值同步到当前已保存主题，“取消”只恢复这个字段的原始状态，不覆盖同时发生的其他主题修改。旧主题缺少字段或字段无效时按 `55` 渲染；正式导入包若字段不是 0–100 的整数则拒绝导入。

该功能使用：

```json
{
  "art": {
    "taskBackgroundStrength": 55
  }
}
```

它只改变任务/对话路由使用的四个遮罩透明度，不改变 Codex 首页或 ChatGPT 首页。

## 新建和切换主题

1. 托盘选择“更换背景图”。
2. 选择纯背景图；不要使用含 UI 的效果截图。
3. 选择“保存当前主题”，输入中文或英文名称。
4. 从“已保存主题”切换。
5. 切到该主题后，通过“任务页背景强度…”保存它自己的数值。

上游 v1.5.11 已用语义/内容指纹识别重复主题，因此同一包或同一内容不会反复生成副本。图片归档仍可能保留历史导入文件；不要仅按文件名判断内容是否重复。

## 更新

```powershell
git pull --ff-only
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\install-dream-skin.ps1
```

更新前退出 Codex 和托盘。主题、活动背景、图片和配置备份保存在 `%LOCALAPPDATA%\CodexDreamSkin`，覆盖受管运行时不会删除它们。

## 验证与日志

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\verify-dream-skin.ps1 `
  -ScreenshotPath "$env:TEMP\codex-dream-skin.png"
```

关键日志：`state.json`、`injector-error.log`、`verify.log`、`start-launch-error.log`。Codex Store 更新后主题停止时，先查看这些文件，再重新安装；不要通过接管 WindowsApps 所有权来绕过问题。

## 完全恢复

随后用生成的截图检查横向溢出和文字对比度，再分别在首页与普通任务页手动检查项目菜单和输入框交互。完整视觉检查项见 [`references/qa-inventory.md`](./references/qa-inventory.md)。

## 更换和保存主题

打开 `Codex Dream Skin - Tray` 后可以：

- 更换 PNG、JPEG 或 WebP 背景图。
- 导入普通 `.zip` 主题包到“已保存主题”（不支持 `.dreamskin`）。
- 保存当前主题并从「已保存主题」切换。
- 暂停或继续显示皮肤。
- 重新应用主题，或完整恢复 Codex。

在 DreamSkin.cc 上，对包含完整三件套且通过审核的兼容主题点击“一键换肤”，浏览器会打开
`dreamskin://apply?version=...`。Windows 会显示原生确认框；确认后客户端只从固定的
`https://api.dreamskin.cc` 下载该版本，核对审核元数据、实际字节数和 SHA-256，再执行与手动 ZIP
导入相同的清单、图片与 Safe CSS 校验并切换主题。Codex 已打开但没有可用皮肤会话时可能重启，确认前
请保存输入。链接不能指定任意下载地址、文件路径或命令，也不能静默应用；不完整的旧主题仍会被客户端拒绝。

导入图片必须是纯背景，不要使用包含窗口、侧栏、输入框、文字或按钮的效果截图。图片上限为 10 MB；宽或高不能超过 16384 像素，总像素不能超过 5000 万。

新的正式 Studio ZIP 必须包含 `manifest.json`、非空 `theme.json`、非空 `theme.css`、恰好一张 `background.webp|jpg|png`，并可选
带 `LICENSE.txt`、`manifest.sig`；文件直接位于根目录或只包一层主题目录。本地简化包也必须恰好包含
`theme.json`、`theme.css` 与其引用图片，且只应来自可信来源。压缩文件上限 32 MiB、最多
32 个条目、解压后最多 64 MiB；路径穿越、链接/reparse、嵌套压缩包和未注册文件会被拒绝。正式包还会
核对平台、最低客户端版本及清单中每个负载文件的大小与 SHA-256。Safe CSS 会在本机导入和每次应用时
复验，通过后只作用于 12 个注册部件；升级前已有的无 CSS legacy 主题仍可切换且不会注入额外 CSS。
预留签名当前不验证。导入只加入主题库，不会改动当前主题；重复内容不会再次写入。同 ID 的新版本会在确认
旧目录身份后原地更新；只有语义指纹完全一致的旧版 `-2`/`-3` 同族目录才会被清理，名称本身不能证明重复，
身份不明时会保留并拒绝覆盖。

也可从托盘选择“打开主题文件夹”，手动把已解压、且直接包含 `theme.json`、`theme.css` 与背景图的完整目录移动到
`%LOCALAPPDATA%\CodexDreamSkin\themes\`。重新打开托盘菜单后即可看到；不要再套一层目录。手动目录
不会经过 ZIP 导入器的归档校验，请只移动可信内容。

## 恢复与卸载快捷方式

恢复官方外观；如果 Codex 正在运行，确认后关闭并重新打开：

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\windows\scripts\restore-dream-skin.ps1 `
  -RestoreBaseTheme -PromptRestart
```

恢复会关闭受管注入会话并恢复安装前外观；已保存主题和图片默认保留。
