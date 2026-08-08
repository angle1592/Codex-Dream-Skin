# Codex Dream Skin — Windows 个人定制分支

[English](./README.en.md) · [上游项目](https://github.com/Fei-Away/Codex-Dream-Skin) · [Windows 详细说明](./windows/README.md)

这是 [`Fei-Away/Codex-Dream-Skin`](https://github.com/Fei-Away/Codex-Dream-Skin) 的个人 Windows 定制分支，当前基于上游 **v1.5.12**。它用于维护我自己的使用方式，不准备向上游提交 PR，也不代表 OpenAI 或上游项目。

本仓库保留上游的本机 CDP 注入、安全校验、主题 ZIP、主题去重、热切换与恢复机制；不会修改 WindowsApps、`app.asar` 或官方 Codex 二进制文件。

本次 v1.5.12 同步保留 Codex 26.727 的新主表面、顶栏、顶部渐变和设置页识别修复，并加入最新的 Windows 主题 schema 与路径校验加固。

## 与上游的区别

| 功能 | 本分支 | 上游 v1.5.12 |
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

> 可下载的用户源图是 [`docs/images/presets/arina-hashimoto-source.png`](./docs/images/presets/arina-hashimoto-source.png)（`1672 × 941`）；源码参考预设使用 [`macos/presets/preset-arina-hashimoto/background.jpg`](./macos/presets/preset-arina-hashimoto/background.jpg)（规范化派生 `2560 × 1440`）。上面两个效果图包含真实 UI，**只作预览，绝不能当背景导入**。背景为用户提供的 AI 生成示例，不代表 OpenAI/Codex 官方视觉或背书；未确认人物与素材权利前不得把它打进公开安装包。

## 它能做什么

- **真·可交互**：侧栏、建议卡、项目选择、输入框都是原生控件，不是整窗假截图贴上去
- **真背景层**：一张 16:9 纯壁纸连续铺满整窗，首页突出氛围，任务页自动降低干扰
- **可换图**：换一张喜欢的纯背景，自适应焦点、安全区和配色后变成你的主题
- **可存主题**：macOS 菜单栏与 Windows 系统托盘都能保存/切换本地主题
- **一键换肤**：在 [DreamSkin.cc](https://dreamskin.cc) 上点一下，客户端核对来源与校验和后直接装上
- **可导入主题包**：两端都可直接选择普通 `.zip`，安全校验后加入本地主题库
- **可恢复**：一键还原官方外观
- **相对安全**：本机回环 CDP 注入，不改官方二进制与签名

## 快速开始

### 普通用户：下载安装包

不需要 clone 仓库，也不需要安装 Node.js 或运行 `.sh` / `.ps1`。从
[GitHub Releases](https://github.com/Fei-Away/Codex-Dream-Skin/releases) 下载对应平台的最新安装包，
按平台文档完成一次图形界面安装：

| 平台 | 下载 | 安装说明 |
|------|------|----------|
| macOS | `CodexDreamSkin-vX.Y.Z.dmg` | [`docs/install-macos.md`](./docs/install-macos.md) |
| Windows | `CodexDreamSkin-Setup-vX.Y.Z.exe` | [`docs/install-windows.md`](./docs/install-windows.md) |

安装后从菜单栏（macOS）或系统托盘（Windows）使用。更新时下载新安装包覆盖安装，主题和图片会保留；
未签名的新下载文件在个别系统上仍可能再次出现一次安全提示，文档列出了放行方法。

### 导入下载的主题

从 DreamSkin.cc 装主题优先用[一键换肤](#一键换肤)。下面是手动导入 `.zip` 的兜底路径，也适用于任何
其他来源的主题包。

在 macOS 菜单栏选择“导入主题 ZIP…”，或在 Windows 托盘选择同名菜单。只支持普通 `.zip`，
不支持 `.dreamskin` 后缀，也不要仅改后缀伪装。正式 Studio 主题包包含 `manifest.json`、
`theme.json`、非空 `theme.css` 和恰好一张 `background.webp|jpg|png`；还可包含 `LICENSE.txt` 和预留的
`manifest.sig`。这些文件可以位于 ZIP 根目录或唯一一层主题目录。导入器会核对适用平台、最低客户端
版本，以及清单中每个负载文件的大小和 SHA-256。`theme.css` 必须通过本机 Safe CSS 校验，导入后只会
作用于 12 个注册部件；每次切换/应用仍会重新校验。`manifest.sig` 当前不参与签名验证。

本地简化 ZIP 也必须恰好包含非空 `theme.json`、非空 `theme.css` 和其引用图片；该格式没有正式清单的
完整性与兼容性声明，只应从可信来源使用。压缩包最大 32 MiB、最多 32 个条目、解压后最多 64 MiB。
导入成功后主题只会加入“已保存的主题”，不会自动替换当前主题；相同内容不会重复写入。同 ID 的新版本会在
确认旧目录身份后原地更新，并仅清理语义指纹完全一致、已确认属于同一主题的旧版 `-2`/`-3` 重复目录；无法
确认身份时会拒绝覆盖，也不会根据名称猜测并删除其他主题。

也可以先手动解压，再把包含 `theme.json`、`theme.css` 和背景图的完整主题目录移动到本机主题库：

- macOS：`~/Library/Application Support/CodexDreamSkinStudio/themes/`
- Windows：`%LOCALAPPDATA%\CodexDreamSkin\themes\`

菜单里有“打开主题文件夹”快捷入口。移动后重新打开菜单/托盘即可；不要再套一层目录，也不要放链接、
嵌套压缩包或缺少三件套的文件夹。手动目录不会经过 ZIP 导入器的归档校验，请只使用可信内容。升级前
已经保存且没有 CSS 的 legacy 主题仍可切换，但不会注入额外 CSS。

### 开发者：从源码运行

仓库内按平台放了现成脚本（实现细节不同，效果都是「主题化 Codex」）：

| 平台 | 目录 | 入口 |
|------|------|------|
| Apple Silicon / Intel Mac | [`macos/`](./macos/) | 双击 `Install Codex Dream Skin.command` |
| Windows | [`windows/`](./windows/) | `scripts/install-dream-skin.ps1` → `start-dream-skin.ps1` |

更细的说明：

- Mac：[`macos/README.md`](./macos/README.md)
- Windows：[`windows/README.md`](./windows/README.md)
- 路径对照：[`docs/platforms.md`](./docs/platforms.md)
- 可直接复制的参考生图模板：[`docs/reference-background-prompt-guide.md`](./docs/reference-background-prompt-guide.md)
- 八种概念方向详细提示词：[`docs/background-generation-prompts.md`](./docs/background-generation-prompts.md)
- 项目记录：[`docs/PROJECT.md`](./docs/PROJECT.md)

## 反馈与贡献

- **Issue：** 请用 [Issue 模板](./.github/ISSUE_TEMPLATE/)（Bug / 功能）；已关闭空白 Issue。提交前建议先跑 Verify / Restore 自检。
- **PR：** 请按 [PR 模板](./.github/pull_request_template.md) 写清改动，并勾选对应自测（如 `macos/tests/run-tests.sh`、verify / restore）。

## 安全边界

- CDP 只绑 `127.0.0.1`，但**没有身份认证**；同一台电脑上的其他进程仍可能连接并读取或控制 renderer
- 暂停主题或只停止 injector 不会关闭已启动 Codex 的调试端口；使用完整 Restore/重启，或退出全部 Codex 后从官方普通入口重新打开，风险窗口才结束
- 不修改官方安装目录与代码签名
- **不会**自动改写 API Key / Base URL；中转与换肤分开
- 完整威胁模型与操作建议见 [`SECURITY.md`](./SECURITY.md)

## 许可与声明

- 见 [`macos/LICENSE`](./macos/LICENSE)（MIT）与 [`macos/NOTICE.md`](./macos/NOTICE.md)
- 非 OpenAI 官方产品；Codex 及相关权利归其权利人
- 随仓库预设及效果图中的人物 / IP 素材仅作主题示意；商用或公开再分发请自行确认肖像、素材与商标权利

---

Star 一下，然后挑一张图，把你的 Codex 变成今天想要的样子。
