#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./scripts/common.sh
source "${PROJECT_ROOT}/scripts/common.sh"

ensure_executables "$PROJECT_ROOT"
load_env_file "${PROJECT_ROOT}/.env"

CONF_DIR="${PROJECT_ROOT}/conf"
TEMP_DIR="${PROJECT_ROOT}/temp"
LOG_DIR="${PROJECT_ROOT}/logs"

CLASH_URL=${CLASH_URL:-}
if [ -z "$CLASH_URL" ]; then
  echo "Error: CLASH_URL is not set. Please set it in .env or export it before running start.sh." >&2
  exit 1
fi

SECRET=${CLASH_SECRET:-$(openssl rand -hex 32)}

CPU_ARCH=$(detect_cpu_arch || true)
if [ -z "${CPU_ARCH:-}" ]; then
  echo "Failed to obtain CPU architecture" >&2
  exit 1
fi

for var in http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY; do
  unset "$var" || true
done

echo -e '\n正在检测订阅地址...'
MSG_OK="Clash订阅地址可访问！"
MSG_FAIL="Clash订阅地址不可访问！"
curl -o /dev/null -L -k -sS --retry 5 -m 10 --connect-timeout 10 -w "%{http_code}" "$CLASH_URL" | grep -E '^[23][0-9]{2}$' &>/dev/null
STATUS=$?
if_success "$MSG_OK" "$MSG_FAIL" $STATUS

echo -e '\n正在下载Clash配置文件...'
MSG_OK="配置文件config.yaml下载成功！"
MSG_FAIL="配置文件config.yaml下载失败，退出启动！"
mkdir -p "$TEMP_DIR"
curl -L -k -sS --retry 5 -m 10 -o "$TEMP_DIR/clash.yaml" "$CLASH_URL"
STATUS=$?
if [ $STATUS -ne 0 ]; then
  for _ in {1..10}; do
    wget -q --no-check-certificate -O "$TEMP_DIR/clash.yaml" "$CLASH_URL" && { STATUS=0; break; }
  done
fi
if_success "$MSG_OK" "$MSG_FAIL" $STATUS

cp -a "$TEMP_DIR/clash.yaml" "$TEMP_DIR/clash_config.yaml"

if [[ "$CPU_ARCH" =~ x86_64 || "$CPU_ARCH" =~ amd64 ]]; then
  echo -e '\n判断订阅内容是否符合clash配置文件标准:'
  bash "${PROJECT_ROOT}/scripts/clash_profile_conversion.sh" "$TEMP_DIR"
  sleep 3
fi

sed -n '/^proxies:/,$p' "$TEMP_DIR/clash_config.yaml" > "$TEMP_DIR/proxy.txt"
cat "$TEMP_DIR/templete_config.yaml" > "$TEMP_DIR/config.yaml"
cat "$TEMP_DIR/proxy.txt" >> "$TEMP_DIR/config.yaml"
cp "$TEMP_DIR/config.yaml" "$CONF_DIR/"

DASHBOARD_DIR="${PROJECT_ROOT}/dashboard/public"
sed -ri "s@^# external-ui:.*@external-ui: ${DASHBOARD_DIR}@g" "$CONF_DIR/config.yaml"
sed -ri "s@(secret: ).*@\1${SECRET}@g" "$CONF_DIR/config.yaml"

HTTP_PORT=$(awk '/^port:/ {print $2; exit}' "$CONF_DIR/config.yaml")

echo -e '\n正在启动Clash服务...'
MSG_OK="服务启动成功！"
MSG_FAIL="服务启动失败！"
if [[ "$CPU_ARCH" =~ x86_64 || "$CPU_ARCH" =~ amd64 ]]; then
  nohup "$PROJECT_ROOT/bin/clash-linux-amd64" -d "$CONF_DIR" &> "$LOG_DIR/clash.log" &
  STATUS=$?
elif [[ "$CPU_ARCH" =~ aarch64 || "$CPU_ARCH" =~ arm64 ]]; then
  nohup "$PROJECT_ROOT/bin/clash-linux-arm64" -d "$CONF_DIR" &> "$LOG_DIR/clash.log" &
  STATUS=$?
elif [[ "$CPU_ARCH" =~ armv7 ]]; then
  nohup "$PROJECT_ROOT/bin/clash-linux-armv7" -d "$CONF_DIR" &> "$LOG_DIR/clash.log" &
  STATUS=$?
else
  echo -e "\033[31m\n[ERROR] Unsupported CPU Architecture！\033[0m"
  exit 1
fi
if_success "$MSG_OK" "$MSG_FAIL" $STATUS

echo ''
echo -e "Clash Dashboard 访问地址: http://<ip>:9090/ui"
echo -e "Secret: ${SECRET}"
echo ''

write_user_env_file "$SECRET" "$HTTP_PORT"
ensure_bashrc_hook
# shellcheck source=/dev/null
source "$HOME/.clash_env.sh"

echo -e "请执行以下命令加载环境变量: source ~/.clash_env.sh\n"
echo -e "请执行以下命令开启系统代理: proxy_on\n"
echo -e "若要临时关闭系统代理，请执行: proxy_off\n"
