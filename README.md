# NoSudoVPN

一套面向「没有 sudo / root 权限」环境的 Clash 启动脚本。按照下列指引，复制命令逐步执行即可完成配置、启动、重启与关闭。

## 0. 使用前准备

- 一台已安装 Bash 的 Linux/macOS 机器（无需 sudo 权限）。
- Clash 订阅链接（支持标准 Clash YAML 或 Base64 订阅，脚本会自动尝试转换）。
- 当前项目目录：`NoSudoVPN-main 3/`（可自行重命名，下面命令以此目录为例）。

## 1. 获取项目文件

如果是通过压缩包下载，请先解压并进入目录；如使用 Git，可直接 clone：

```bash
git clone https://github.com/oyjr/NoSudoVPN.git
cd NoSudoVPN
```

> 若你已经位于项目目录，可直接运行 `pwd` 确认路径。

## 2. 配置订阅信息

1. 复制环境配置模板：
   ```bash
   cp .env.example .env
   ```
2. 编辑 `.env`，填入你的订阅地址：
   ```bash
   vim .env
   ```
   将 `CLASH_URL` 更新为真实订阅链接；如希望自定义 Dashboard 密钥，设置 `CLASH_SECRET`，否则留空即可自动生成。

## 3. 首次启动 Clash

```bash
bash start.sh
```
启动脚本会自动完成：
- 校验订阅地址 → 下载 `temp/clash.yaml`。
- 必要时调用 subconverter 转换格式 → 生成 `temp/config.yaml` → 覆盖 `conf/config.yaml`。
- 按当前 CPU 架构选择恰当的 Clash 二进制，后台运行并写日志到 `logs/clash.log`。
- 读取 `conf/config.yaml` 的 `port`，生成 `~/.clash_env.sh`，并在 `~/.bashrc` 中追加一次 `source ~/.clash_env.sh`。
- 自动 `source ~/.clash_env.sh`，让本次会话可以直接使用 `proxy_on` / `proxy_off`。
- 在终端输出 Dashboard 访问地址和 Secret（请记录）。

看到 `服务启动成功！ [  OK  ]` 后，Clash 已在后台运行。

## 4. 验证运行状态

**查看 Clash 进程：**
```bash
pgrep -fal clash-linux-
```

**验证代理是否可用：**
```bash
proxy_on
curl -I https://www.google.com
proxy_off
```

**访问 Dashboard：** 打开浏览器访问 `http://localhost:9090/ui`（或替换 `<ip>` 为服务器地址），在 Secret 处填入启动脚本输出的值。

## 5. 日常操作命令

| 操作          | 命令               | 说明 |
|---------------|--------------------|------|
| 手动开启代理  | `proxy_on`         | 设置当前 shell 的 HTTP/HTTPS 代理变量 |
| 手动关闭代理  | `proxy_off`        | 清空代理变量 |
| 重启 Clash    | `bash restart.sh`  | 不重新下载订阅，直接按现有 `conf/config.yaml` 重启 |
| 停止 Clash    | `bash shutdown.sh` | 终止 Clash、执行 `proxy_off`、清理 `~/.clash_env.sh` 与 `.bashrc` 钩子 |

> `restart.sh` 与 `shutdown.sh` 均可在任何时刻运行，脚本会自行处理后台进程。

## 6. 更新订阅 / 修改配置

- **更新订阅内容：** 直接重新执行 `bash start.sh`，脚本会下载最新订阅并覆盖配置。
- **修改监听端口：** 编辑 `conf/config.yaml` 中的 `port:`，然后运行 `bash restart.sh`。下次 `start.sh` 会同步更新 `~/.clash_env.sh` 中的端口。
- **调整其他 Clash 规则：** 直接修改 `conf/config.yaml`，随后运行 `bash restart.sh` 使新配置生效。

## 7. 常见日志位置

- `logs/clash.log`：Clash 主程序输出。
- `logs/subconverter.log`：订阅转换失败时的排查依据。

## 8. 清理/卸载

若不再需要，可运行：
```bash
bash shutdown.sh
rm -f ~/.clash_env.sh
# 如需移除项目目录，自行删除整个 NoSudoVPN 文件夹
```
`shutdown.sh` 会自动删除 `.bashrc` 中的 `source ~/.clash_env.sh` 钩子。

---

所有脚本复用了 `scripts/common.sh` 中的公共函数；若计划扩展功能，建议在该文件中添加新的工具函数，保持逻辑集中，避免重复编码。
