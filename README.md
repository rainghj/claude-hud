<<<<<<< HEAD
# ClaudeHud 🖥️

> Claude Code 的增强状态栏 HUD — 实时显示模型、Token 使用量和上下文窗口状态。

![效果展示](screenshots/demo.png)

## ✨ 特性

- **实时 Token 监控** — 显示本次会话的输入/输出 token 数
- **上下文进度条** — 直观看到上下文窗口使用了多少（百分比 + 进度条）
- **模型信息** — 显示当前模型名称和推理努力级别
- **仓库信息** — 自动识别当前 Git 仓库（owner/name）
- **缓存统计** — 显示 Prompt Caching 的创建/读取量
- **一键安装** — `bash install.sh` 或 PowerShell 均可启用
- **自由开关** — 随时切换，无需卸载
- **优雅降级** — 所有字段缺失时自动跳过，不会报错

## 📸 效果

```
deepseek-v4-flash  |  ████████░░ 45% (12.5k in · 3.2k out)  |  owner/repo
```

```
claude-sonnet-4-6 [high]  |  ░░░░░░░░░░ 12% (2.1k in · 0.5k out)
```

```
claude-opus-4-8  |  ████████████████████ 92% (85.3k in · 12.1k out)  |  cache rd 2.1k
```

---

## 🚀 Windows 安装

### 方法 1：PowerShell 一键安装（推荐）

```powershell
# 在 ClaudeHud 目录中，右键 → "在终端中打开"，然后:
.\install.ps1
```

如果遇到执行策略限制，先运行:
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

**PowerShell 管理命令：**
```powershell
.\install.ps1          # 安装并启用
.\install.ps1 -On      # 启用
.\install.ps1 -Off     # 禁用（临时关闭）
.\install.ps1 -Status  # 查看当前状态
.\install.ps1 -Remove  # 完全卸载
```

### 方法 2：Git Bash 安装

```bash
# 在 Git Bash 中
bash install.sh
```

**Git Bash 管理命令：**
```bash
bash toggle.sh          # 查看状态
bash toggle.sh on       # 启用
bash toggle.sh off      # 禁用
bash uninstall.sh       # 卸载
```

---

## 🍎 macOS / Linux 安装

```bash
git clone https://github.com/YOUR_USERNAME/claude-hud.git
cd claude-hud
bash install.sh
```

管理命令:
```bash
bash toggle.sh on       # 启用
bash toggle.sh off      # 禁用
bash uninstall.sh       # 卸载
```

---

## ⚙️ 手动安装

如果不想用安装脚本，也可以手动操作：

```bash
# 1. 复制脚本
mkdir -p ~/.claude
cp claude-hud.sh ~/.claude/claude-hud.sh
chmod +x ~/.claude/claude-hud.sh
```

**2. 编辑 `~/.claude/settings.json`，添加:**
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/claude-hud.sh"
  }
}
```

**3. 重启 Claude Code 即可生效。**

---

## ❄️ 数据字段参考

状态栏脚本通过 stdin 接收 Claude Code 的会话状态 JSON，可用字段：

| 字段 | 说明 | 示例 |
|------|------|------|
| `model.display_name` | 模型名称 | `deepseek-v4-flash` |
| `effort.level` | 推理努力级别 | `high` |
| `context_window.used_percentage` | 上下文使用率 | `45` |
| `context_window.remaining_percentage` | 上下文剩余率 | `55` |
| `context_window.current_usage.input_tokens` | 本次输入 tokens | `12500` |
| `context_window.current_usage.output_tokens` | 本次输出 tokens | `3200` |
| `context_window.total_input_tokens` | 累计输入 tokens | `125000` |
| `context_window.current_usage.cache_creation_input_tokens` | 缓存创建 tokens | `4200` |
| `context_window.current_usage.cache_read_input_tokens` | 缓存读取 tokens | `2100` |
| `workspace.repo.owner` | 仓库所有者 | `my-user` |
| `workspace.repo.name` | 仓库名称 | `my-repo` |
| `version` | Claude Code 版本 | `2.0.0` |
| `session_id` | 会话 ID | `abc123` |

## 🔧 依赖

- **`jq`** — 必须，用于解析 JSON
  - **Windows (Git Bash)**: 通常已预装
  - **macOS**: `brew install jq`
  - **Ubuntu/Debian**: `sudo apt install jq`
- **`bc` 或 `awk`** — 可选，用于数值格式化（通常系统自带）

## 📁 项目结构

```
claude-hud/
├── claude-hud.sh           # ⭐ 状态栏核心脚本
├── install.ps1             # Windows PowerShell 安装/管理
├── install.sh              # Unix / Git Bash 安装脚本
├── toggle.sh               # 快速开关 (Unix/Git Bash)
├── uninstall.sh            # 卸载脚本 (Unix/Git Bash)
├── config/
│   └── example-settings.json   # 配置示例
├── screenshots/
│   └── demo.png            # 效果截图
├── README.md               # 本文件
└── LICENSE                 # MIT 许可证
```

## 🤝 贡献

欢迎提 Issue 和 PR！如果想贡献代码：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing`)
3. 提交改动 (`git commit -m 'Add something amazing'`)
4. 推送到分支 (`git push origin feature/amazing`)
5. 创建 Pull Request

## 📄 许可证

[MIT](LICENSE)

---

**ClaudeHud** — 让 Claude Code 的状态栏更有用。❤️
