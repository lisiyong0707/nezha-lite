#!/usr/bin/env bash
# Nezha Lite 一键部署到 GitHub Pages
# 用法：./deploy.sh [仓库名] [哪吒WebSocket地址]
# 示例：./deploy.sh nezha-lite wss://nezha.example.com/api/v1/ws/server
# Windows 请在 Git Bash 或 WSL 中运行
set -euo pipefail
cd "$(dirname "$0")"

REPO="${1:-nezha-lite}"
WS_URL="${2:-}"

command -v git >/dev/null || { echo "❌ 需要先安装 git"; exit 1; }
command -v gh  >/dev/null || { echo "❌ 需要先安装 GitHub CLI：https://cli.github.com"; exit 1; }

# 1. 登录 GitHub（已登录会自动跳过）
if ! gh auth status >/dev/null 2>&1; then
  echo "▶ 需要登录 GitHub"
  gh auth login
fi
OWNER="$(gh api user -q .login)"

# 2. 写入哪吒 WebSocket 地址（可选，也可以之后用 ?ws= 参数传入）
if [ -n "$WS_URL" ]; then
  WS_ESC="$(printf '%s' "$WS_URL" | sed 's/[&|\\]/\\&/g')"
  sed -i.bak "s|wsUrl: \"[^\"]*\"|wsUrl: \"${WS_ESC}\"|" index.html
  rm -f index.html.bak
  echo "▶ 已写入 wsUrl：$WS_URL"
else
  echo "▶ 未指定 WebSocket 地址，页面将以演示模式运行（可用 ?ws=wss://... 临时指定）"
fi

# 3. 提交并推送
[ -d .git ] || git init -q -b main
git add -A
git commit -q -m "Deploy Nezha Lite" 2>/dev/null || echo "▶ 没有新的改动需要提交"

if gh repo view "$OWNER/$REPO" >/dev/null 2>&1; then
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$REPO.git"
  git push -u origin main
else
  # Pages 免费版要求公开仓库
  gh repo create "$REPO" --public --source . --remote origin --push
fi

# 4. 启用 Pages（构建方式：GitHub Actions）
gh api -X POST "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 \
  || gh api -X PUT "repos/$OWNER/$REPO/pages" -f build_type=workflow >/dev/null 2>&1 \
  || echo "⚠ 自动启用 Pages 失败，请到 仓库 Settings → Pages → Source 选 GitHub Actions"

# 5. 触发部署（首次推送时 Pages 可能还没启用，这里补跑一次）
sleep 3
gh workflow run pages.yml --repo "$OWNER/$REPO" >/dev/null 2>&1 || true

echo
echo "✅ 完成。1~2 分钟后访问：https://${OWNER}.github.io/${REPO}/"
echo "   部署进度：gh run watch --repo ${OWNER}/${REPO}"
