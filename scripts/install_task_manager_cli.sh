#!/usr/bin/env bash
set -euo pipefail

DEFAULT_LOCAL_SOURCE="$HOME/Documents/coding/my/task-manager-cli"
DEFAULT_GIT_SOURCE="git@github.com:WatchaAI/task-manager-cli.git"
SOURCE="${TASK_MANAGER_CLI_SOURCE:-}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

is_git_source() {
  case "$1" in
    git@*:*|ssh://*|https://*.git|http://*.git)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

install_package() {
  local package_ref="$1"
  if [ -n "${TASK_MANAGER_CLI_PREFIX:-}" ]; then
    npm install --global --prefix "$TASK_MANAGER_CLI_PREFIX" "$package_ref"
  else
    npm install --global "$package_ref"
  fi
}

install_from_dir() {
  local source_dir="$1"
  local pack_dir="$2"

  if [ ! -f "$source_dir/package.json" ]; then
    echo "Source directory has no package.json: $source_dir" >&2
    exit 1
  fi

  (
    cd "$source_dir"
    if [ -f package-lock.json ]; then
      npm ci
    else
      npm install
    fi
    if npm pkg get scripts.build 2>/dev/null | grep -qvE '^\{\}$|^null$'; then
      npm run build
    fi
    npm pack --pack-destination "$pack_dir" >/dev/null
  )

  local tarball
  tarball="$(find "$pack_dir" -maxdepth 1 -name '*.tgz' -print -quit)"
  if [ -z "$tarball" ]; then
    echo "npm pack did not produce a tarball" >&2
    exit 1
  fi
  install_package "$tarball"
}

main() {
  require_cmd node
  require_cmd npm

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT

  if [ -z "$SOURCE" ]; then
    if [ -d "$DEFAULT_LOCAL_SOURCE" ]; then
      SOURCE="$DEFAULT_LOCAL_SOURCE"
    else
      SOURCE="$DEFAULT_GIT_SOURCE"
    fi
  fi

  if [ -d "$SOURCE" ]; then
    install_from_dir "$SOURCE" "$TMP_DIR"
  elif [ -f "$SOURCE" ]; then
    install_package "$SOURCE"
  elif is_git_source "$SOURCE"; then
    require_cmd git
    git clone --depth 1 "$SOURCE" "$TMP_DIR/task-manager-cli"
    install_from_dir "$TMP_DIR/task-manager-cli" "$TMP_DIR"
  else
    install_package "$SOURCE"
  fi

  local tm_bin
  if [ -n "${TASK_MANAGER_CLI_PREFIX:-}" ] && [ -x "$TASK_MANAGER_CLI_PREFIX/bin/tm" ]; then
    tm_bin="$TASK_MANAGER_CLI_PREFIX/bin/tm"
  else
    tm_bin="$(command -v tm || true)"
  fi

  if [ -z "$tm_bin" ]; then
    echo "Installed package, but tm is not on PATH." >&2
    echo "Check npm global bin or TASK_MANAGER_CLI_PREFIX/bin." >&2
    exit 1
  fi

  "$tm_bin" --help >/dev/null
  echo "task-manager-cli installed: $tm_bin"
  "$tm_bin" --json db
}

main "$@"
