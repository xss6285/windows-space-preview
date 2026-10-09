# 空格文件速览

Windows 10/11 空格预览配置技能。选中文件按空格即可预览，点击预览窗口右上角按钮可用 Windows 默认软件打开原文件。

支持常见图片、PSD/PSB 合成图像、PDF 兼容的 Adobe Illustrator AI、PDF、TXT，以及常用 Word `.doc/.docx`、Excel `.xls/.xlsx` 和 PowerPoint `.pptx` 文档。

## 安装

下载并解压整个仓库，联网后以普通用户双击 `Install.cmd`。安装器配置 QuickLook、独立 OfficeViewer、开机启动，并将 skill 安装到个人 Codex 技能目录。仅复制 skill 文件不会自动安装预览程序。

安装完成后在资源管理器中选中文件，按空格预览，按 Esc 关闭。日常预览无需运行 Codex。

Codex 中可使用：`使用 $windows-space-preview 检查并修复空格预览。`

## 范围

AI 需要包含 PDF 兼容内容；旧 `.ppt` 和 WPS 专有 `.wps/.et/.dps` 未包含。默认应用打开按钮使用接收者电脑的文件关联，不安装 Photoshop、Illustrator 或 WPS，不自动改变关联。

依赖 Windows、网络与 winget（Microsoft App Installer）。已在原电脑检查安装流程和相关样例，尚未在另一台全新 Windows 电脑验证。

本仓库只提供技能、脚本和说明，不包含第三方二进制或个人设计文件。软件从 [QuickLook](https://github.com/QL-Win/QuickLook) 和 [OfficeViewer](https://github.com/QL-Win/QuickLook.Plugin.OfficeViewer) 官方渠道获取。
