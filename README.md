# NoSudoVPN

在无 `sudo` 权限的环境下部署 Clash 代理的一组脚本。仓库基于上游项目精简，移除了重复资源，并把通用逻辑集中在共享工具脚本中便于维护。

## 快速开始

```bash
cp .env.example .env   # 复制配置模板
vim .env               # 填写 CLASH_URL，必要时设置 CLASH_SECRET
bash start.sh          # 启动 Clash
```

## 工作流程速览

1. **准备**
   - `start.sh` 会自动确保 `bin/`、`scripts/` 等目录下可执行文件具备执行权限。
   - 加载 `.env`，清理已有的代理相关环境变量。

2. **启动 (`bash start.sh`)**
   - 校验并下载订阅 `clash.yaml`，必要时调用 subconverter 做格式转换。
   - 在 `temp/` 中拼装最终 `config.yaml` 并写入 `conf/`；更新 Dashboard `external-ui` 和 `secret`。
   - 根据当前 CPU 架构启动对应 Clash 二进制，日志输出到 `logs/clash.log`。
   - 读取 `conf/config.yaml` 的 `port`，生成 `~/.clash_env.sh` 并追加一次 `source ~/.clash_env.sh` 到 `~/.bashrc`，随后自动 `source` 以启用 `proxy_on` / `proxy_off`。
   - 终端显示 Dashboard 访问地址 `http://<ip>:9090/ui` 与可用的 Secret。

3. **使用期间**
   - 通过 `proxy_on` / `proxy_off` 控制当前会话的 HTTP/HTTPS 代理。
   - 浏览器访问 `http://localhost:9090/ui`（或 `<ip>` 对应地址）管理 Clash。

4. **重启 (`bash restart.sh`)**
   - 停止正在运行的 Clash 进程后，直接按当前架构重新启动，不重新下载订阅。

5. **关闭 (`bash shutdown.sh`)**
   - 终止 Clash 进程，调用 `proxy_off`，删除 `~/.clash_env.sh` 并移除 `.bashrc` 中的钩子。

## 常用排查

- `logs/clash.log`：Clash 自身日志。
- `logs/subconverter.log`：订阅转换失败时的排查线索。

如需扩展功能，建议从 `scripts/common.sh` 复用现成的工具函数，保持脚本整洁。
