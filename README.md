# 🖼️ AiImgPaste

![AutoHotkey v2](https://img.shields.io/badge/AutoHotkey-v2-blue)
![Windows](https://img.shields.io/badge/platform-Windows-lightgrey)
![License](https://img.shields.io/badge/license-GPL%20v2-green)

一个用于 **Windows + AI 工具链** 的轻量级截图处理工具，专为与 Claude、Codex、Cursor 等 AI 客户端配合使用而设计。

> 📸 截图 → ⌨️ 快捷键 → 🤖 AI 识别，一气呵成！

## 💡 为什么需要这个工具？

在使用 AI 工具时，我们经常需要让 AI 分析截图内容。但在 Windows 环境下会遇到以下问题：

- 📋 **传统终端窗口**（如 PowerShell、CMD）**不支持直接粘贴图片**，只能粘贴文本
- 📁 手动保存截图、输入路径的过程繁琐且低效

**AiImgPaste 解决方案：**
- ✅ 自动将截图保存为永久文件
- ✅ 直接粘贴出 `@文件路径` 格式，AI 工具可立即识别
- ✅ 支持 WSL 路径转换，适配各种开发环境
- ✅ 一键操作，无需手动处理

## ✨ 核心功能

- 🎯 **一键保存**: 剪贴板图片自动保存为 PNG 格式
- 🔗 **智能路径**: 自动生成 `@路径` 格式，方便 AI 工具识别
- 🐧 **WSL 兼容**: 支持 Windows 和 WSL 路径格式互转
- 📁 **文件支持**: 除截图外，还支持从资源管理器复制的图片文件
- ⚡ **轻量高效**: 基于 AutoHotkey v2，无额外依赖
- ⚙️ **高度可配置**: 托盘菜单设置，支持自定义快捷键、保存路径等

## 🎬 使用演示

```
1. 截屏 (Win+Shift+S) 或复制图片文件
2. 按下快捷键 (默认: Alt+Shift+V)
3. 自动粘贴: @C:\Users\YourName\Desktop\Screens\2024-11\20241112-143022.png
4. AI 工具自动识别图片内容
```

## 🚀 快速开始

### 系统要求

- Windows 10/11
- [AutoHotkey v2](https://www.autohotkey.com/download/) (必须是 v2 版本)

### 安装步骤

1. **下载 AutoHotkey v2**
   ```
   https://www.autohotkey.com/download/
   ```

2. **克隆本仓库**
   ```bash
   git clone https://github.com/StillFlood/AiImgPaste.git
   cd AiImgPaste
   ```

3. **运行脚本**
   - 右键 `AiPasteImg.ahk` → "以管理员身份运行" (推荐)
   - 或右键 → "Compile Script" 生成 exe 文件后以管理员身份运行

> ⚠️ **重要提示**：在某些终端（如 PowerShell）中使用时，需要**以管理员权限运行**程序，否则无法正常粘贴文本。

### 首次配置

1. 右键托盘图标 → "设置"
2. 配置保存目录（默认：桌面/Screens）
3. 选择路径格式（Windows 或 WSL）
4. 自定义快捷键和前缀

## ⚙️ 配置选项

| 设置项 | 默认值 | 说明 |
|--------|--------|------|
| 保存目录 | `Desktop\Screens` | 图片保存路径 |
| WSL 路径 | 关闭 | 开启后输出 `/mnt/c/...` 格式 |
| 前缀 | `@` | 路径前的标识符 |
| 后缀 | ` ` (空格) | 路径后的自定义文本 |
| 快捷键 | `Alt+Shift+V` | 触发热键组合 |
| 托盘通知 | 开启 | 是否显示操作提示 |
| 异步保存 | 开启 | 异步保存图片，快速响应 |
| 界面语言 | 中文 | 支持中文/English（右键托盘切换） |

## 🛠️ 高级功能

### 快捷键格式

- `!+v` = Alt + Shift + V
- `^!p` = Ctrl + Alt + P  
- `#+s` = Win + Shift + S

### WSL 路径转换

Windows 路径自动转换为 WSL 格式：
```
C:\Users\Name\file.png  →  /mnt/c/Users/Name/file.png
```

### 开机自启

右键托盘图标 → "开机自启" 可设置系统启动时自动运行。

## 🔧 开发说明

### 项目结构

```
AiImgPaste/
├── AiPasteImg.ahk          # 主程序文件
├── README.md               # 项目说明
├── screenshots/            # 默认保存目录
│   └── .gitkeep           # 保持目录结构
├── .gitignore             # Git 忽略文件
└── LICENSE                # 许可证文件
```

### 编译打包

使用 AutoHotkey v2 内置编译器：
```ahk
Ahk2Exe.exe /in AiPasteImg.ahk /out AiImgPaste.exe /icon sflood.ico
```

## 🤝 兼容性

### 测试过的 AI 工具

- ✅ Claude (Anthropic)
- ✅ Cursor
- ✅ GitHub Copilot Chat
- ✅ ChatGPT Web/Desktop
- ✅ WSL 环境下的各种终端工具

### 支持的图片格式

- 📷 屏幕截图 (剪贴板)
- 🖼️ PNG/JPG/BMP 文件
- 📎 从资源管理器复制的图片

## 🐛 故障排除

**Q: 快捷键不起作用？**
A: 检查是否与其他软件冲突，可在设置中修改快捷键组合。

**Q: 图片保存失败？**
A: 确保保存目录有写入权限，检查磁盘空间是否充足。

**Q: WSL 路径不正确？**
A: 确认在设置中已启用"使用 WSL 路径"选项。

**Q: 在 PowerShell 终端无法粘贴？**
A: **需要以管理员权限运行脚本或编译后的程序**。某些终端（如 PowerShell）需要管理员权限才能接收模拟键盘输入。右键点击程序 → "以管理员身份运行"。

## 📄 许可证

本项目基于 GPL v2 许可证开源。

## 🙏 致谢

- [AutoHotkey](https://www.autohotkey.com/) - 强大的 Windows 自动化工具
- 感谢所有提供反馈和建议的用户

---

<div align="center">

**如果这个工具对你有帮助，请考虑给个 ⭐ Star！**

</div>
