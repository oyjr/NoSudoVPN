#!/bin/bash
# Common helpers shared by project scripts.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

success() {
  echo -en "\033[60G[\033[1;32m  OK  \033[0;39m]\r"
  return 0
}

failure() {
  local rc=$?
  echo -en "\033[60G[\033[1;31mFAILED\033[0;39m]\r"
  [ -x /bin/plymouth ] && /bin/plymouth --details
  return $rc
}

action() {
  local message rc
  message=$1
  echo -n "$message "
  shift
  "$@" && success || failure
  rc=$?
  echo
  return $rc
}

if_success() {
  local ok_message fail_message status
  ok_message=$1
  fail_message=$2
  status=$3
  if [ "$status" -eq 0 ]; then
    action "$ok_message" /bin/true
  else
    action "$fail_message" /bin/false
    exit 1
  fi
}

load_env_file() {
  local env_file=$1
  if [ -f "$env_file" ]; then
    # shellcheck disable=SC1090
    source "$env_file"
  fi
}

detect_cpu_arch() {
  local arch candidates candidate
  candidates=(
    "uname -m"
    "arch"
    "/usr/bin/uname -m"
    "dpkg-architecture -qDEB_HOST_ARCH_CPU"
    "dpkg-architecture -qDEB_BUILD_ARCH_CPU"
  )
  for candidate in "${candidates[@]}"; do
    if command -v ${candidate%% *} >/dev/null 2>&1; then
      arch=$(eval "$candidate" 2>/dev/null | awk 'NR==1{print $NF}')
      if [ -n "$arch" ]; then
        echo "$arch"
        return 0
      fi
    fi
  done
  return 1
}

ensure_executables() {
  local root=$1
  chmod +x "$root"/bin/* 2>/dev/null
  chmod +x "$root"/scripts/* 2>/dev/null
  [ -f "$root/tools/subconverter/subconverter" ] && chmod +x "$root/tools/subconverter/subconverter"
}

write_user_env_file() {
  local secret=$1
  local port=${2:-7890}
  cat <<EOF2 > "$HOME/.clash_env.sh"
export CLASH_DASHBOARD_SECRET=${secret}

proxy_on() {
  export http_proxy=http://127.0.0.1:${port}
  export https_proxy=http://127.0.0.1:${port}
  export all_proxy=socks5://127.0.0.1:${port}
  export HTTP_PROXY=\$http_proxy
  export HTTPS_PROXY=\$https_proxy
  export ALL_PROXY=\$all_proxy
  echo "已开启代理"
}

proxy_off() {
  unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
  echo "已关闭代理"
}

Proxy_on() { proxy_on; }
Proxy_off() { proxy_off; }
EOF2
}

ensure_bashrc_hook() {
  local hook='source ~/.clash_env.sh'
  if [ -f "$HOME/.bashrc" ] && ! grep -Fxq "$hook" "$HOME/.bashrc"; then
    echo "$hook" >> "$HOME/.bashrc"
  fi
}

remove_bashrc_hook() {
  local hook='source ~/.clash_env.sh'
  if [ -f "$HOME/.bashrc" ] && grep -Fxq "$hook" "$HOME/.bashrc"; then
    grep -Fxv "$hook" "$HOME/.bashrc" > "$HOME/.bashrc.codex.tmp"
    mv "$HOME/.bashrc.codex.tmp" "$HOME/.bashrc"
  fi
}

clear_user_env_file() {
  rm -f "$HOME/.clash_env.sh"
}

stop_clash_processes() {
  local pids
  pids=$(pgrep -f 'clash-linux-' 2>/dev/null || true)
  if [ -n "$pids" ]; then
    # shellcheck disable=SC2046
    kill -9 $pids
  fi
  return 0
}

start_clash_service() {
  local project_root=$1
  local conf_dir=$2
  local log_dir=$3
  local arch binary status

  arch=$(detect_cpu_arch || true)
  if [ -z "${arch:-}" ]; then
    echo "无法识别CPU架构" >&2
    return 1
  fi

  mkdir -p "$log_dir"
  case "$arch" in
    x86_64|amd64) binary="$project_root/bin/clash-linux-amd64" ;;
    aarch64|arm64) binary="$project_root/bin/clash-linux-arm64" ;;
    armv7*) binary="$project_root/bin/clash-linux-armv7" ;;
    *) echo "不支持的CPU架构: $arch" >&2; return 1 ;;
  esac

  if [ ! -x "$binary" ]; then
    echo "缺少可执行文件: $binary" >&2
    return 1
  fi

  nohup "$binary" -d "$conf_dir" &> "$log_dir/clash.log" &
  status=$?
  return $status
}

read_yaml_value() {
  local file=$1
  local key=$2
  local line
  [ -f "$file" ] || return 1
  line=$(grep -E "^[[:space:]]*${key}:[[:space:]]*.*" "$file" | head -n1 || true)
  if [ -z "$line" ]; then
    return 1
  fi
  line=${line#*:}
  line=${line%%#*}
  line=$(echo "$line" | tr -d '"' | awk '{$1=$1;print}')
  if [ -n "$line" ]; then
    printf '%s\n' "$line"
    return 0
  fi
  return 1
}

proxy_port_from_config() {
  local file=$1
  local value
  for key in mixed-port port socks-port; do
    value=$(read_yaml_value "$file" "$key" || true)
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      echo "$value"
      return 0
    fi
  done
  echo "7890"
}

secret_from_config() {
  local file=$1
  local value
  value=$(read_yaml_value "$file" "secret" || true)
  if [ -n "$value" ]; then
    echo "$value"
    return 0
  fi
  return 1
}
