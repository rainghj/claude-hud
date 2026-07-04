#!/usr/bin/env bash
# ============================================================================
# ClaudeHud 快速开关脚本
# 启用/禁用 Claude Code 状态栏
#
# 用法:
#   bash toggle.sh         # 查看当前状态
#   bash toggle.sh on      # 启用
#   bash toggle.sh off     # 禁用
#   bash toggle.sh status  # 查看当前状态
# ============================================================================

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"
COMMENT_MARKER="// __CLAUDE_HUD_DISABLED__"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ---- 检查 settings.local.json 是否存在 ----
if [ ! -f "$SETTINGS_FILE" ]; then
  echo -e "${YELLOW}settings.local.json 不存在，状态栏未安装。${NC}"
  exit 0
fi

# ---- 检查是否有 statusLine 配置 ----
has_statusline() {
  jq -e '.statusLine' "$SETTINGS_FILE" &>/dev/null
}

# ---- 检测当前状态 ----
get_status() {
  if ! has_statusline; then
    echo "not_installed"
  elif jq -e '.statusLine | type == "object" and has("command")' "$SETTINGS_FILE" &>/dev/null; then
    echo "enabled"
  else
    echo "disabled"
  fi
}

show_status() {
  local status
  status=$(get_status)
  case "$status" in
    enabled)
      echo -e "${GREEN}✓ 状态栏已启用${NC}"
      # 显示具体配置
      echo ""
      echo "当前配置:"
      jq '.statusLine' "$SETTINGS_FILE"
      ;;
    disabled)
      echo -e "${RED}✗ 状态栏已禁用${NC}"
      ;;
    not_installed)
      echo -e "${YELLOW}⚠ 未安装 ClaudeHud 状态栏${NC}"
      echo "请先运行 bash install.sh 安装"
      ;;
  esac
}

# ---- 启用 ----
enable_hud() {
  local status
  status=$(get_status)

  case "$status" in
    enabled)
      echo -e "${GREEN}✓ 状态栏已经启用${NC}"
      return 0
      ;;
    not_installed)
      echo -e "${RED}错误: 未安装 ClaudeHud${NC}"
      echo "请先运行 bash install.sh"
      return 1
      ;;
    disabled)
      # 恢复备份中保存的原始 statusLine 配置
      # 读取之前保存的原始配置
      local raw
      raw=$(jq -r '.statusLine // empty' "$SETTINGS_FILE" 2>/dev/null || echo "")
      if [ -n "$raw" ]; then
        # 替换为启用的配置
        local tmp
        tmp=$(mktemp)
        jq '.statusLine.command |= sub("^#"; "")' "$SETTINGS_FILE" > "$tmp" 2>/dev/null || cp "$SETTINGS_FILE" "$tmp"
        # 如果上面的方法不行，直接用 jq 确保 statusLine 是正常对象
        jq '.statusLine = {"type": "command", "command": "bash '"$CLAUDE_DIR/claude-hud.sh"'"}' "$SETTINGS_FILE" > "$tmp"
        mv "$tmp" "$SETTINGS_FILE"
        echo -e "${GREEN}✓ 状态栏已启用${NC}"
      fi
      ;;
  esac
}

# ---- 禁用 ----
disable_hud() {
  local status
  status=$(get_status)

  case "$status" in
    disabled)
      echo -e "${YELLOW}⚠ 状态栏已经禁用${NC}"
      return 0
      ;;
    not_installed)
      echo -e "${RED}错误: 未安装 ClaudeHud${NC}"
      return 1
      ;;
    enabled)
      # 保留配置但设置 command 为空字符串来禁用
      local tmp
      tmp=$(mktemp)
      jq '.statusLine.command = ""' "$SETTINGS_FILE" > "$tmp"
      mv "$tmp" "$SETTINGS_FILE"
      echo -e "${YELLOW}⚠ 状态栏已禁用${NC}"
      echo "运行 bash toggle.sh on 重新启用"
      ;;
  esac
}

# ---- 主逻辑 ----
case "${1:-status}" in
  on|enable|start)
    enable_hud
    ;;
  off|disable|stop)
    disable_hud
    ;;
  status|--status|--help|-h)
    show_status
    ;;
  *)
    echo "用法: bash toggle.sh [on|off|status]"
    echo ""
    show_status
    ;;
esac
