#!/usr/bin/env bash
# ============================================================================
# ClaudeHud 卸载脚本
# 移除 ClaudeHud 状态栏配置
#
# 用法:
#   bash uninstall.sh          # 卸载（确认提示）
#   bash uninstall.sh --force  # 强制卸载，不提示
# ============================================================================

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"
TARGET_SCRIPT="$CLAUDE_DIR/claude-hud.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     ClaudeHud 卸载程序              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# 确认
if [ "${1:-}" != "--force" ]; then
  echo -e "${YELLOW}将执行以下操作:${NC}"
  [ -f "$TARGET_SCRIPT" ] && echo "  • 删除 $TARGET_SCRIPT"
  [ -f "$SETTINGS_FILE" ] && echo "  • 从 $SETTINGS_FILE 中移除 statusLine 配置"
  echo ""
  read -r -p "确认卸载? [y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo -e "${YELLOW}卸载已取消${NC}"
    exit 0
  fi
fi

# 1. 删除脚本
if [ -f "$TARGET_SCRIPT" ]; then
  rm "$TARGET_SCRIPT"
  echo -e "${GREEN}✓ 已删除 $TARGET_SCRIPT${NC}"
else
  echo -e "${YELLOW}⚠ 脚本文件不存在，跳过${NC}"
fi

# 2. 从 settings.local.json 移除 statusLine
if [ -f "$SETTINGS_FILE" ]; then
  if jq -e '.statusLine' "$SETTINGS_FILE" &>/dev/null; then
    # 备份
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    # 移除 statusLine
    jq 'del(.statusLine)' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo -e "${GREEN}✓ 已从 $SETTINGS_FILE 移除 statusLine 配置${NC}"
    echo -e "  ${YELLOW}备份保存为 ${SETTINGS_FILE}.bak.*${NC}"
  else
    echo -e "${YELLOW}⚠ settings.local.json 中没有 statusLine 配置，跳过${NC}"
  fi
fi

echo ""
echo -e "${GREEN}卸载完成!${NC}"
echo "重启 Claude Code 后状态栏将不再显示。"
