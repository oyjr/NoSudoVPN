#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

TEMP_DIR=${1:-$(default_temp_dir)}
RAW_FILE="${TEMP_DIR}/clash.yaml"
OUTPUT_FILE="${TEMP_DIR}/clash_config.yaml"
LOG_FILE="${PROJECT_ROOT}/logs/subconverter.log"

mkdir -p "${PROJECT_ROOT}/logs"

if [ ! -f "$RAW_FILE" ]; then
  echo "订阅内容不存在: ${RAW_FILE}" >&2
  exit 1
fi

raw_content=$(cat "$RAW_FILE")

has_clash_sections() {
  printf '%s' "$1" | awk '/^proxies:/{p=1} /^proxy-groups:/{g=1} /^rules:/{r=1} p&&g&&r{exit} END{if(p&&g&&r) exit 0; else exit 1}'
}

if has_clash_sections "$raw_content"; then
  echo "订阅内容符合clash标准"
  printf '%s' "$raw_content" > "$OUTPUT_FILE"
  exit 0
fi

if printf '%s' "$raw_content" | base64 -d &>/dev/null; then
  decoded_content=$(printf '%s' "$raw_content" | base64 -d)
  if has_clash_sections "$decoded_content"; then
    echo "解码后的内容符合clash标准"
    printf '%s' "$decoded_content" > "$OUTPUT_FILE"
    exit 0
  fi

  echo "解码后的内容不符合clash标准，尝试将其转换为标准格式"
  "${PROJECT_ROOT}/tools/subconverter/subconverter" -g &>> "$LOG_FILE"
  if [ -f "$OUTPUT_FILE" ] && has_clash_sections "$(cat "$OUTPUT_FILE")"; then
    echo "配置文件已成功转换成clash标准格式"
    exit 0
  fi

  echo "配置文件转换标准格式失败"
  exit 1
fi

echo "订阅内容不符合clash标准，无法转换为配置文件"
exit 1
