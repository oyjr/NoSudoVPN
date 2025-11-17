#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./scripts/common.sh
source "${PROJECT_ROOT}/scripts/common.sh"

download_config() {
  local url=$1
  local dest=$2
  local tmp success=1
  tmp=$(mktemp)

  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL --retry 3 --connect-timeout 10 --max-time 60 "$url" -o "$tmp"; then
      success=0
    fi
  fi

  if [ $success -ne 0 ] && command -v wget >/dev/null 2>&1; then
    if wget -q -O "$tmp" "$url"; then
      success=0
    fi
  fi

  if [ $success -ne 0 ]; then
    rm -f "$tmp"
    echo "无法下载订阅，请检查网络或订阅地址: $url" >&2
    return 1
  fi

  mv "$tmp" "$dest"
}

set_yaml_field() {
  local file=$1
  local key=$2
  local value=$3
  local escaped
  escaped=$(printf '%s' "$value" | sed -e 's/[&@]/\\&/g')
  if grep -Eq "^[[:space:]#]*${key}:" "$file"; then
    sed -i -E "s@^[[:space:]#]*${key}:[[:space:]]*.*@${key}: ${escaped}@" "$file"
  else
    printf '\n%s: %s\n' "$key" "$value" >> "$file"
  fi
}

configure_clash_file() {
  local file=$1
  local dashboard_dir=$2
  local secret=$3
  set_yaml_field "$file" "external-controller" "0.0.0.0:9090"
  set_yaml_field "$file" "external-ui" "$dashboard_dir"
  set_yaml_field "$file" "secret" "$secret"
  set_yaml_field "$file" "allow-lan" "true"
}

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  else
    head -c 16 /dev/urandom | hexdump -v -e '/1 "%02x"'
  fi
}

ensure_executables "$PROJECT_ROOT"
load_env_file "${PROJECT_ROOT}/.env"

CLASH_URL=${1:-${CLASH_URL:-}}
if [ -z "$CLASH_URL" ]; then
  cat <<'EOF' >&2
未提供订阅地址。
请通过以下方式之一设置：
  1. 运行时传参：bash start.sh "https://example.com/clash.yaml"
  2. 在 .env 中设置 CLASH_URL=订阅地址
EOF
  exit 1
fi

SECRET=${CLASH_SECRET:-$(generate_secret)}
CONF_DIR="${PROJECT_ROOT}/conf"
LOG_DIR="${PROJECT_ROOT}/logs"
DASHBOARD_DIR="${PROJECT_ROOT}/dashboard/public"
CONFIG_FILE="${CONF_DIR}/config.yaml"

mkdir -p "$CONF_DIR" "$LOG_DIR"

for var in http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY; do
  unset "$var" || true
done

echo -e "\n=== 启动 NoSudoVPN ==="
echo "订阅地址: $CLASH_URL"

action "下载 Clash 配置" download_config "$CLASH_URL" "$CONFIG_FILE"
action "写入 Dashboard/Secret 配置" configure_clash_file "$CONFIG_FILE" "$DASHBOARD_DIR" "$SECRET"

HTTP_PORT=$(proxy_port_from_config "$CONFIG_FILE")

action "停止已存在的 Clash 进程" stop_clash_processes
action "启动 Clash 服务" start_clash_service "$PROJECT_ROOT" "$CONF_DIR" "$LOG_DIR"

write_user_env_file "$SECRET" "$HTTP_PORT"
ensure_bashrc_hook
# shellcheck source=/dev/null
source "$HOME/.clash_env.sh"

cat <<EOF

Clash 已在后台运行！
- Dashboard 地址: http://<服务器IP>:9090/ui
- Dashboard Secret: ${SECRET}
- HTTP/HTTPS 代理端口: ${HTTP_PORT}
- 订阅来源: ${CLASH_URL}

当前 Shell 已加载 proxy_on/proxy_off 函数，新开终端也会自动加载（.bashrc 钩子已写入）。请执行 proxy_on / Proxy_on 开启代理，proxy_off / Proxy_off 关闭代理。
如需刷新节点，重新运行 bash start.sh 即可。
EOF
