#!/usr/bin/env bash
# ============================================================================
# ClaudeHud — Claude Code 状态栏 HUD
# 显示模型、Token 使用量、上下文进度、仓库信息等
#
# 用法: Claude Code 自动调用，通过 settings.json 配置:
#   "statusLine": { "type": "command", "command": "bash ~/.claude/claude-hud.sh" }
#
# 数据来源: stdin 接收 Claude Code 的会话状态 JSON
# ============================================================================

# 不使用 set -e，避免 jq/awk 等命令失败时脚本无输出

# 确保 jq 在 PATH 中（Windows Git Bash 可能没有 ~/bin）
PATH="$HOME/bin:/usr/bin:/bin:$PATH"

# 读取 stdin 的 JSON
input=$(cat)

# 字段不存在时输出空字符串，实现优雅降级（|| true 防 jq 找不到导致失败）
model=$(echo "$input" | jq -r '.model.display_name // empty' 2>/dev/null || echo "")
effort=$(echo "$input" | jq -r '.effort.level // empty' 2>/dev/null || echo "")
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null || echo "")

in_tok=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty' 2>/dev/null || echo "")
out_tok=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // empty' 2>/dev/null || echo "")

parts=()

# ---- 模型名称 ----
if [ -n "$model" ]; then
  label="$model"
  # 追加 effort 信息
  if [ -n "$effort" ] && [ "$effort" != "medium" ]; then
    label="$label [$effort]"
  fi
  parts+=("$label")
fi

# ---- Token / 上下文使用情况 ----
if [ -n "$used" ]; then
  pct=$(printf "%.0f" "$used")

  # 进度条: █ 表示已用, ░ 表示剩余，按使用率变色
  # ANSI 颜色: \033[32m=绿(0-60%) \033[33m=黄(60-85%) \033[31m=红(85-100%)
  filled=$(( pct / 10 ))
  [ "$filled" -gt 10 ] && filled=10
  empty_b=$(( 10 - filled ))

  if [ "$pct" -lt 60 ]; then color="\033[32m"
  elif [ "$pct" -lt 85 ]; then color="\033[33m"
  else color="\033[31m"
  fi
  dim="\033[90m"
  reset="\033[0m"

  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}${color}█${reset}"; done
  for ((i=0; i<empty_b; i++)); do bar="${bar}${dim}░${reset}"; done

  token_info="${bar} ${color}${pct}%${reset}"

  # 格式化 token 数为可读形式 (1234 -> 1.2k)
  format_tok() {
    local val=$1
    if [ -z "$val" ] || [ "$val" = "null" ]; then
      echo ""
      return
    fi
    if [ "$val" -ge 1000000 ]; then
      # 使用 awk 避免依赖 bc
      awk "BEGIN { printf \"%.1fM\", $val / 1000000 }"
    elif [ "$val" -ge 1000 ]; then
      awk "BEGIN { printf \"%.1fk\", $val / 1000 }"
    else
      echo "${val}t"
    fi
  }

  # 显示本次会话的输入/输出 tokens
  if [ -n "$in_tok" ] && [ -n "$out_tok" ]; then
    in_fmt=$(format_tok "$in_tok")
    out_fmt=$(format_tok "$out_tok")
    token_info="$token_info (${in_fmt} in · ${out_fmt} out)"
  fi

  # token_info 加入 parts
  parts+=("$token_info")
fi

# ---- Git 分支信息 ----
# 直接从文件系统获取，比 JSON 中的仓库信息更实用
branch=$(git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -n "$branch" ] && [ "$branch" != "HEAD" ]; then
  parts+=("${branch}")
fi

# ---- 输出 ----
result=""
sep=""
for part in "${parts[@]}"; do
  result="${result}${sep}${part}"
  sep="  |  "
done

# 有内容才输出，否则显示模型名保底
if [ -n "$result" ]; then
  printf '%b\n' "$result"
elif [ -n "$model" ]; then
  printf '%b\n' "$model"
fi
