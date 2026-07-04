#!/usr/bin/env bash
# ============================================================================
# ClaudeHud 安装脚本
# 将 ClaudeHud 状态栏安装到 ~/.claude/ 并配置 settings.json
#
# 用法:
#   bash install.sh          # 安装
#   bash install.sh --help   # 显示帮助
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.local.json"
TARGET_SCRIPT="$CLAUDE_DIR/claude-hud.sh"
CONFIG_KEY="statusLine"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔══════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     ClaudeHud 安装程序              ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
echo ""

# ---- 检测依赖 ----
echo -e "${YELLOW}[1/4] 检测依赖...${NC}"
has_jq=true
has_bc=true

if ! command -v jq &>/dev/null; then
  echo -e "  ${RED}✗ jq 未安装${NC}"
  echo "    请安装 jq: https://jqlang.github.io/jq/download/"
  has_jq=false
else
  echo -e "  ${GREEN}✓ jq $(jq --version 2>&1 | head -1)${NC}"
fi

if ! command -v bc &>/dev/null; then
  echo -e "  ${YELLOW}⚠ bc 未安装 (将使用 awk 替代)${NC}"
  has_bc=false
else
  echo -e "  ${GREEN}✓ bc${NC}"
fi

if [ "$has_jq" = false ]; then
  echo ""
  echo -e "${RED}错误: jq 是必须的依赖，请先安装 jq。${NC}"
  exit 1
fi
echo ""

# ---- 复制脚本 ----
echo -e "${YELLOW}[2/4] 复制 claude-hud.sh 到 $CLAUDE_DIR/...${NC}"

if [ ! -d "$CLAUDE_DIR" ]; then
  mkdir -p "$CLAUDE_DIR"
  echo -e "  ${GREEN}✓ 创建目录 $CLAUDE_DIR${NC}"
fi

cp "$SCRIPT_DIR/claude-hud.sh" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
echo -e "  ${GREEN}✓ 已安装到 $TARGET_SCRIPT${NC}"
echo ""

# ---- 配置 settings.json ----
echo -e "${YELLOW}[3/4] 配置 statusLine...${NC}"

# 检测是否已有 statusLine 配置
if [ -f "$SETTINGS_FILE" ]; then
  if jq -e '.statusLine' "$SETTINGS_FILE" &>/dev/null; then
    echo -e "  ${YELLOW}⚠ settings.json 中已有 statusLine 配置，跳过${NC}"
    echo "    如需覆盖，请手动编辑 $SETTINGS_FILE"
  else
    # 备份原文件
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    # 添加 statusLine 配置
    jq '.statusLine = {"type": "command", "command": "bash ~/.claude/claude-hud.sh"}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo -e "  ${GREEN}✓ 已添加 statusLine 配置到 $SETTINGS_FILE${NC}"
  fi
else
  # 创建新 settings.json
  cat > "$SETTINGS_FILE" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/claude-hud.sh"
  }
}
EOF
  echo -e "  ${GREEN}✓ 已创建 $SETTINGS_FILE 并添加 statusLine 配置${NC}"
fi
echo ""

# ---- 安装完成 ----
echo -e "${YELLOW}[4/4] 安装完成!${NC}"
echo ""
echo -e "  ${GREEN}✓${NC} claude-hud.sh 已安装到: ${CYAN}$TARGET_SCRIPT${NC}"
echo -e "  ${GREEN}✓${NC} statusLine 已配置到: ${CYAN}$SETTINGS_FILE${NC}"
echo ""
echo -e "  ${CYAN}━━━━ 使用说明 ━━━━${NC}"
echo -e "  ${GREEN}▶${NC} 启动 Claude Code 即可看到状态栏"
echo -e "  ${GREEN}▶${NC} 临时关闭: ${CYAN}bash toggle.sh off${NC}"
echo -e "  ${GREEN}▶${NC} 重新开启: ${CYAN}bash toggle.sh on${NC}"
echo -e "  ${GREEN}▶${NC} 卸载:     ${CYAN}bash $SCRIPT_DIR/uninstall.sh${NC}"
echo ""
echo -e "  ${YELLOW}提示: 如果状态栏不显示，请重启 Claude Code 会话${NC}"
echo ""
