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

2. 首次配置并启动，以下三种方法三选一（只需执行一次即可完成订阅拉取与服务启动）：

   - 1、使用订阅链接：
     ```bash
     bash start.sh "https://你的订阅地址/clash.yaml"
     ```
   - 2、使用本地 YAML（例如你从其他客户端导出的配置）：
     ```bash
     bash start.sh ./conf/my-clash.yaml
     ```
   - 3、或通过 `.env` 固定来源：
     ```bash
     cp .env.example .env
     # 方案 A：设置 CLASH_URL=你的订阅链接
     # 方案 B：设置 CLASH_FILE=/path/to/config.yaml
     # (可选) 设置 CLASH_SECRET=固定 Dashboard 密码
     bash start.sh
     ```

   > 只要订阅内容不需要刷新，后续无需再传入链接或重新运行 `bash start.sh`。需要更新节点列表（例如订阅变动）时，再执行 `bash start.sh`。

   首次启动会输出以下信息，请记录：

   - Clash Dashboard 地址：`http://<服务器IP>:9090/ui`
   - Dashboard Secret（用于登录 Dashboard）
   - 本地 HTTP/HTTPS 代理端口

3. 日常使用流程：
   - 登录服务器或打开新终端后，只需执行 `proxy_on`（或 `Proxy_on`）即可启用代理，执行 `proxy_off`（或 `Proxy_off`）即可关闭。
   - 需要切换节点时，直接登录 Dashboard（下一节）操作即可，Clash 会实时生效，不必重跑脚本。

## 节点选择与 Dashboard

1. 打开浏览器访问 `http://<服务器IP>:9090/ui`（本地环境可用 `localhost`）。  
2. 输入启动脚本输出的 Secret，或执行 `echo $CLASH_DASHBOARD_SECRET` 查看。  
3. 进入 Dashboard → 「Proxies」页面选择想要的节点。切换结果立刻作用于当前 Clash 进程，无需重新执行 `bash start.sh`。

## 自定义订阅 & Secret

- 订阅来源完全由你控制：可在运行时传入，也可写入 `.env` 的 `CLASH_URL`；若已有现成 YAML，可将路径填入 `CLASH_FILE` 或直接 `bash start.sh ./your.yaml`。
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
- 订阅下载失败：确认服务器能访问订阅地址，可换网络/稍后再试；或将 YAML 保存到本地并执行 `bash start.sh ./your.yaml`，也可以在 `.env` 中设置 `CLASH_FILE`。
- Secret 遗失：执行 `grep -m1 '^secret:' conf/config.yaml` 或 `echo $CLASH_DASHBOARD_SECRET` 查看。

## 卸载/清理

```bash
bash shutdown.sh
rm -f ~/.clash_env.sh
# 如需彻底移除，删除整个 NoSudoVPN 目录
```

`shutdown.sh` 会自动移除 `.bashrc` 中的 `source ~/.clash_env.sh` 语句，避免对环境造成残留影响。
