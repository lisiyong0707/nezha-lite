# Nezha Lite

轻量哪吒监控面板：单文件 `index.html`，无依赖，通过 WebSocket 读取哪吒 v1 的服务器状态。
未配置地址时为演示模式。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `index.html` | 面板本体 |
| `.github/workflows/pages.yml` | 推送到 `main` 后自动发布到 GitHub Pages |
| `deploy.sh` | 一键脚本：写入配置、建仓库、推送、启用 Pages |

## 方式一：一键脚本

先安装 [git](https://git-scm.com) 和 [GitHub CLI](https://cli.github.com)，然后：

```bash
chmod +x deploy.sh
./deploy.sh nezha-lite wss://你的哪吒域名/api/v1/ws/server
```

两个参数都可省略：仓库名默认 `nezha-lite`，不填地址则为演示模式。
Windows 请在 Git Bash 或 WSL 中运行。

## 方式二：手动命令

```bash
# 1. 登录并建仓库（Pages 免费版需要公开仓库）
gh auth login
git init -b main
git add -A
git commit -m "Deploy Nezha Lite"
gh repo create nezha-lite --public --source . --remote origin --push

# 2. 启用 Pages，构建方式选 GitHub Actions
OWNER=$(gh api user -q .login)
gh api -X POST repos/$OWNER/nezha-lite/pages -f build_type=workflow

# 3. 触发部署并查看进度
gh workflow run pages.yml
gh run watch

# 访问地址：https://$OWNER.github.io/nezha-lite/
```

不用命令行也行：在 GitHub 网页新建仓库，上传这些文件，然后到
**Settings → Pages → Build and deployment → Source** 选 **GitHub Actions**。

## 配置哪吒地址

任选其一：

1. 改 `index.html` 里的 `CONFIG.wsUrl`
2. 访问时加参数：`https://你的用户名.github.io/nezha-lite/?ws=wss://你的哪吒域名/api/v1/ws/server`

## 后续更新

改完 `index.html` 直接推送即可，Actions 会自动重新部署：

```bash
git add -A && git commit -m "update" && git push
```

## 常见问题

- **页面能打开但没数据**：GitHub Pages 是 https，必须用 `wss://`，不能用 `ws://`。
- **连不上**：面板和哪吒不同域，浏览器不会带登录 cookie，所以服务器需要对游客可见。
  如果反代（Nginx、Caddy、Cloudflare）限制了来源域名，要放行 `https://你的用户名.github.io`。
- **全部显示离线**：说明 `last_active` 的格式和预期不同，把一条真实返回数据发给开发者调整。
- **隐私**：仓库是公开的，写进 `wsUrl` 的域名别人能看到。介意的话不要写死，
  改用 `?ws=` 参数访问。
- **访问 GitHub 慢**：同一个 `index.html` 也可以直接扔到 Cloudflare Pages、Vercel，
  或任意 Nginx 静态目录，都不需要构建。
