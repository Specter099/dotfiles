#!/usr/bin/env bash
# Claude Code status line script

input=$(cat)

# --- Directory ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir=$(basename "$cwd")

# --- Git branch and status ---
git_part=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  indicators=""
  if ! git -C "$cwd" diff --no-ext-diff --quiet --cached 2>/dev/null; then
    indicators="${indicators}+"
  fi
  if ! git -C "$cwd" diff --no-ext-diff --quiet 2>/dev/null; then
    indicators="${indicators}*"
  fi
  git_part=" \033[90m|\033[0m \033[36m${branch}${indicators}\033[0m"
fi

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // ""')

# --- Context usage ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used_pct" ]; then
  ctx_str=$(printf "%.0f%%" "$used_pct")
  if awk "BEGIN{exit !($used_pct > 80)}"; then
    ctx_color="\033[31m"
  elif awk "BEGIN{exit !($used_pct > 50)}"; then
    ctx_color="\033[33m"
  else
    ctx_color="\033[32m"
  fi
  ctx_part=" \033[90m|\033[0m ${ctx_color}ctx:${ctx_str}\033[0m"
else
  ctx_part=""
fi

# --- AWS profile ---
aws_profile="${AWS_PROFILE:-}"
if [ -n "$aws_profile" ]; then
  aws_part=" \033[90m|\033[0m \033[33maws:${aws_profile}\033[0m"
else
  aws_part=""
fi

# --- Python venv ---
virtual_env="${VIRTUAL_ENV:-}"
if [ -n "$virtual_env" ]; then
  venv_name=$(basename "$virtual_env")
  if [ "$venv_name" = ".venv" ] || [ "$venv_name" = "venv" ]; then
    venv_name=$(basename "$(dirname "$virtual_env")")
  fi
  venv_part=" \033[90m|\033[0m \033[35mpy:${venv_name}\033[0m"
else
  venv_part=""
fi

# --- Assemble ---
printf "%b%b \033[90m|\033[0m \033[34m%s\033[0m%b%b%b\n" \
  "\033[1m${dir}\033[0m" \
  "$git_part" \
  "$model" \
  "$ctx_part" \
  "$aws_part" \
  "$venv_part"
