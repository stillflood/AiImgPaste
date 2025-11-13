# 更新日志

所有重要的项目变更都会记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)，
并且本项目遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [1.0.0] - 2025-11-13

### 新增
- 🎉 首个正式版本发布
- 📸 支持剪贴板图片自动保存为 PNG 格式
- 📁 支持从资源管理器复制的图片文件直接获取路径
- 🔗 自动生成 `@路径` 格式，便于 AI 工具识别
- 🐧 支持 Windows 和 WSL 路径格式互转（`C:\...` ↔ `/mnt/c/...`）
- ⌨️ 可配置的快捷键绑定（默认 Alt+Shift+V）
- ⚙️ 完整的托盘菜单设置界面
- 🚀 开机自启功能
- 🔔 可选的托盘通知提示
- 📝 支持自定义路径前缀（如 `@`, `@file` 等）
- ✏️ 支持路径后缀自定义文本（可包含换行符）
- 📂 按月份自动组织截图文件（`YYYY-MM/`）
- 🕐 文件名采用时间戳命名（`yyyyMMdd-HHmmss.png`）
- 💾 配置文件自动持久化保存
- 🎨 使用 sflood.ico 作为程序图标
- 🏗️ 提供 32 位和 64 位编译版本

### 技术特性
- 基于 AutoHotkey v2 开发
- 使用 PowerShell 进行图片格式转换
- 完整的 GUI 设置界面
- INI 配置文件管理
- 无需安装 AutoHotkey 的独立可执行文件

### 兼容性
- ✅ Windows 10/11
- ✅ WSL/WSL2 环境
- ✅ Claude、Cursor、GitHub Copilot 等 AI 工具
- ✅ 32 位和 64 位 Windows 系统

### 文档
- 📖 完整的 README.md 使用说明
- 📜 贡献指南（CONTRIBUTING.md）
- ⚖️ GPL v2 开源许可证
- 🔄 GitHub Actions 自动构建和发布