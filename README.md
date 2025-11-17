# NoSudoVPN

一套针对「没有 sudo / root 权限」的 Linux Shell 脚本，帮助你快速拉起 Clash、控制代理开关，并通过 Dashboard 选择节点。准备好个人的 Clash 订阅链接后即可使用。

## 功能亮点

- 自动下载订阅 → 写入配置 → 按 CPU 架构启动 Clash。
- 自动生成 Dashboard Secret，并挂载项目自带的 Dashboard 前端，可直接切换节点。
- 写入 `~/.clash_env.sh`，提供 `proxy_on` / `Proxy_on` / `proxy_off` / `Proxy_off` 一键开关代理。
- 全程无需 `sudo`/`root`，适合云服务器受限账号或学生机环境。

## 快速开始

1. 获取项目文件：

   ```bash
   git clone https://github.com/oyjr/NoSudoVPN.git
   cd NoSudoVPN
   ```

2. 配置订阅（任选其一）并启动（首次执行即可完成订阅拉取与服务启动）：

   - 运行时传参：
     ```bash
     bash start.sh "https://你的订阅地址/clash.yaml"
     ```
   - 或使用 `.env`：
     ```bash
     cp .env.example .env
     # 编辑 .env，设置 CLASH_URL=你的订阅链接
     # (可选) 设置 CLASH_SECRET=固定Dashboard密码
     bash start.sh
     ```

   > 只要订阅内容不需要刷新，后续无需再传入链接或重新运行 `bash start.sh`。日常只需使用 `proxy_on`/`proxy_off` 或按需执行 `bash restart.sh` 即可。需要更新节点时再运行 `bash start.sh`。

   首次启动会输出以下信息，请记录：

   - Clash Dashboard 地址：`http://<服务器IP>:9090/ui`
   - Dashboard Secret（用于登录 Dashboard）
   - 本地 HTTP/HTTPS 代理端口

3. 在当前 Shell 加载代理函数：

   ```bash
   source ~/.clash_env.sh
   ```

   之后即可使用：

   ```bash
   proxy_on   # 或 Proxy_on，开启代理
   proxy_off  # 或 Proxy_off，关闭代理
   ```

## 节点选择与 Dashboard

1. 打开浏览器访问 `http://<服务器IP>:9090/ui`（本地环境可用 `localhost`）。  
2. 输入启动脚本输出的 Secret，或执行 `echo $CLASH_DASHBOARD_SECRET` 查看。  
3. 进入 Dashboard → 「Proxies」页面选择想要的节点，生效即时，无需重启。

## 自定义订阅 & Secret

- 订阅来源完全由你控制：可在运行时传入，也可写入 `.env` 的 `CLASH_URL`。
- 留空 `CLASH_SECRET` 会自动生成随机值；想复用固定 Secret 时可在 `.env` 中预设。

## 常用命令

| 目标             | 命令               | 说明 |
|------------------|--------------------|------|
| 更新订阅并重启   | `bash start.sh`    | 需要拉取最新订阅或更换订阅时执行 |
| 仅重启后端       | `bash restart.sh`  | 日常使用场景，沿用现有 `conf/config.yaml` |
| 停止服务并清理   | `bash shutdown.sh` | 终止 Clash，执行 `proxy_off` 并删除 `~/.clash_env.sh` |
| 查看日志         | `tail -f logs/clash.log` | 追踪 Clash 输出 |

> 修改 `conf/config.yaml`（端口、规则等）后运行 `bash restart.sh` 即可让更改生效。

## 日志与排障

- Clash 主日志：`logs/clash.log`
- 订阅下载失败：确认服务器能访问订阅地址，或通过参数/`.env` 替换订阅。
- Secret 遗失：执行 `grep -m1 '^secret:' conf/config.yaml` 或 `echo $CLASH_DASHBOARD_SECRET` 查看。

## 卸载/清理

```bash
bash shutdown.sh
rm -f ~/.clash_env.sh
# 如需彻底移除，删除整个 NoSudoVPN 目录
```

`shutdown.sh` 会自动移除 `.bashrc` 中的 `source ~/.clash_env.sh` 语句，避免对环境造成残留影响。
