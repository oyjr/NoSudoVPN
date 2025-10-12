#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./scripts/common.sh
source "${PROJECT_ROOT}/scripts/common.sh"

CONF_DIR="${PROJECT_ROOT}/conf"
LOG_DIR="${PROJECT_ROOT}/logs"

MSG_OK="服务关闭成功！"
MSG_FAIL="服务关闭失败！"
stop_clash_processes
STATUS=$?
if_success "$MSG_OK" "$MSG_FAIL" $STATUS

sleep 3

CPU_ARCH=$(detect_cpu_arch || true)
if [ -z "${CPU_ARCH:-}" ]; then
  echo -e "\033[31m\n[ERROR] Failed to obtain CPU architecture！\033[0m"
  exit 1
fi

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
