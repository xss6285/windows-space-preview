---
name: windows-space-preview
description: 在 Windows 10/11 安装、配置和修复空格预览，支持图片、PSD/PSB、PDF兼容AI、TXT及WPS常用办公文档，并通过窗口右上角按钮用默认软件打开原文件。用于预览失效、格式和文件关联诊断。
---

# Windows 空格预览

通过 QuickLook 提供资源管理器中“选中文件，按空格预览；再按空格或 Esc 关闭”的体验。Skill 是安装、配置和排障流程，常驻快捷键由 QuickLook 实现。

## 操作

- 首次启用完整功能或用户要求“安装后与分享者一样”时，运行 `scripts/setup-preview.ps1`，一次部署 QuickLook、开机启动和独立 OfficeViewer。可以先加 `-CheckOnly` 只读检查前提。首次仅安装 skill 文件不会自动执行程序安装；安装 skill 后必须完成这一步，并对用户明确区分。
- 完整安装需要普通用户会话和联网访问官方 GitHub/winget。不要以管理员运行 QuickLook；管理员权限与普通资源管理器权限不一致可能导致快捷键失效。缺少 winget 时按脚本指引安装微软 App Installer，再重试。
- 先运行 `scripts/manage-preview.ps1 -Action Status` 查看安装、进程、启动项和渲染组件。需要诊断特定文件时加 `-FilePath <完整路径>`；只读文件头，不修改设计文件。
- 用户要求启用或替换预览时，运行 `-Action Install`。通过官方 winget 包 `QL-Win.QuickLook` 安装，设置当前用户开机启动并启动程序。安装失败就停止并报告真实错误，不循环安装。
- 已安装但未启动时运行 `-Action Start`。运行 `-Action Restart` 只重启 QuickLook；排障时保留日志和用户配置，不重置配置或重启资源管理器。
- 在普通权限的文件资源管理器中选中一个文件测试；焦点不能在搜索框、地址栏或重命名输入框。分别验证图片、PSD、AI。仅进程存在或解码成功不能称为完成了空格交互验收；没有 UI 验证能力时明确报告验证范围。
- 如果其他程序也截获空格，先识别冲突程序。仅在用户授权范围内关闭相关预览功能或卸载对应程序。PowerToys 包含许多其他工具，不把“修复预览”默认为卸载整个 PowerToys。

## 格式边界

- TXT 使用 QuickLook 内置 TextViewer，不需要另装插件。完整安装需检查 `TextViewer` 状态。中文乱码时在预览器的编码选项切换合适编码，不改变原文件编码、不覆盖保存；TXT 的双击应用由 Windows 默认关联决定。
- 从预览打开原文件：QuickLook 4.5.0 的标题栏右上角已有 `buttonOpen` 图标按钮，悬停提示“用 [默认应用名称] 打开”；点击调用 Windows Shell 打开原路径并关闭预览。另一个“打开方式”按钮供临时选择程序。不要将图标按钮说成已新增了常驻文字按钮；不需要修改或重新编译 QuickLook。
- 用户要求 PSD→Photoshop、AI→Illustrator、办公/PDF→WPS 时，优先遵从其“与双击相同”的规则。运行 `scripts/check-default-apps.ps1` 只读检查当前用户文件关联。分享到其他电脑后使用该电脑的默认应用，无法保证软件已安装或默认关联相同。若不符合用户期望，引导在 Windows 设置的默认应用中更改；不要直接写入带 Hash 校验的 UserChoice 注册表，不默默更改其他类型关联。

- Word/Excel/PPTX：用户要求办公预览时运行 `scripts/install-office-preview.ps1 -WorkDirectory <工作目录>`，从官方发布下载独立 OfficeViewer，安装到当前用户插件目录后重启 QuickLook。内置 OfficeViewer 依赖系统预览处理器，独立插件不要求启动 WPS 或安装 Microsoft Office。安装失败保留日志并报告，不修改文件关联。
- 独立 OfficeViewer v6 支持 `.doc/.docx/.docm/.rtf`、`.xls/.xlsx/.xlsm`、`.pptx/.pptm/.potx/.potm`。文件由 WPS 创建也按格式处理。旧版 `.ppt` 和 WPS 专有 `.wps/.et/.dps` 不在该插件支持列表，不能声称均已支持；可建议用户另存标准格式副本，不改后缀、不覆盖原稿。插件更新时重新确认格式列表。
- Office 文档验证要区分“插件能识别格式”“渲染成功”和“真实文件空格验收”。复杂版式、加密文件、外部链接和宏可能存在限制，不运行宏、不访问文档外部链接。分享 skill 时提供官方插件下载流程，不捆绑 Syncfusion 二进制；自行开发或重新分发需按官方 README 的许可要求处理。
- OfficeViewer v6 对 Windows 文件属性为“只读”的文档显示不支持提示。不要自动移除原稿只读属性，可在工作目录创建预览副本；该属性限制不代表普通预览会保存或覆盖原稿。

- 常见图片由内置 ImageViewer 处理。PSD/PSB 查看合成图像，不提供图层编辑；不能保证所有颜色模式、超大文件或没有兼容合成图像的 PSD 都能预览。
- AI 是 Adobe Illustrator 文件，不是人工智能文件。内置 PDFViewer 根据 `%PDF` 文件头识别 PDF 兼容 AI，不需要改后缀或额外插件。
- `%!PS` 表示 PostScript 类型 AI，其他文件头可能是非 PDF 兼容 AI。不要承诺全部 AI 可直接预览。只有用户希望处理此类文件时才继续研究官方 PostScript 插件或 Illustrator 导出方案。
- 现代非 PDF 兼容 AI 需要 Illustrator 生成预览副本，或用户在 Illustrator 另存副本并勾选“创建 PDF 兼容文件”。不要覆盖原稿或批量重新保存；未得到授权不要改变 Illustrator 保存首选项、启动 Adobe 自动化或安装 Ghostscript。
- 遇到 PSD 空白，检查 Photoshop 的“最大化 PSD 和 PSB 文件兼容性”及该文件是否已有合成图像。若需重存，使用另存副本。

## 来源与更新

使用官方 GitHub/winget，避免第三方下载站；安装版本由当前清单决定，不固定旧版本。安装改变系统状态仍须遵守工具权限。

- 项目及安装：[QL-Win/QuickLook](https://github.com/QL-Win/QuickLook)
- Adobe 支持范围：[官方维护者说明](https://github.com/QL-Win/QuickLook/issues/1516)
- 独立办公预览：[OfficeViewer 官方项目](https://github.com/QL-Win/QuickLook.Plugin.OfficeViewer)
- 日志/设置：安装版通常在 `%APPDATA%\pooi.moe\QuickLook`；便携版在程序目录的 `UserData`。日志可能包含用户文件路径，不完整上传。

完成后报告安装版本、启动状态、实际验证过的格式及剩余限制，不将“已安装”写成“全部文件均已验证”。
