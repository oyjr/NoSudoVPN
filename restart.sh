#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./scripts/common.sh
source "${PROJECT_ROOT}/scripts/common.sh"

CONF_DIR="${PROJECT_ROOT}/conf"
LOG_DIR="${PROJECT_ROOT}/logs"
CONFIG_FILE="${CONF_DIR}/config.yaml"

if [ ! -s "$CONFIG_FILE" ]; then
  echo "未找到配置文件: $CONFIG_FILE，请先执行 bash start.sh" >&2
  exit 1
fi

action "停止已存在的 Clash 进程" stop_clash_processes
sleep 1
action "重新启动 Clash 服务" start_clash_service "$PROJECT_ROOT" "$CONF_DIR" "$LOG_DIR"

HTTP_PORT=$(proxy_port_from_config "$CONFIG_FILE")
SECRET=$(secret_from_config "$CONFIG_FILE" || true)
write_user_env_file "${SECRET:-UNSET}" "$HTTP_PORT"
ensure_bashrc_hook

cat <<EOF

Clash 已重新启动。
- Dashboard 地址: http://<服务器IP>:9090/ui
- Dashboard Secret: ${SECRET:-请查看配置文件}
- 当前代理端口: ${HTTP_PORT}
如需重新拉取订阅，请运行 bash start.sh。
EOF
