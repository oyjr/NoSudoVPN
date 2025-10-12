#!/bin/bash
set -euo pipefail

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=./scripts/common.sh
source "${PROJECT_ROOT}/scripts/common.sh"

MSG_OK="服务关闭成功！"
MSG_FAIL="服务关闭失败！"
stop_clash_processes
STATUS=$?
if_success "$MSG_OK" "$MSG_FAIL" $STATUS

if [ -f "$HOME/.clash_env.sh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.clash_env.sh"
  proxy_off || true
fi

clear_user_env_file
remove_bashrc_hook

echo -e "\n服务关闭成功，系统代理已关闭。\n"
