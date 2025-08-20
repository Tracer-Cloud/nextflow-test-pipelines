#!/usr/bin/env bash
set -e

# WDL
OS_NAME="$(uname -s)"

if ! command -v miniwdl >/dev/null 2>&1; then
  echo "miniwdl not found in PATH; ensure you're running via 'pixi run ...' so dependencies are active."
fi

if ! command -v docker >/dev/null 2>&1; then
  case "$OS_NAME" in
    Linux*)
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y docker.io || true
        sudo systemctl enable --now docker || true
      elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y docker || true
        sudo systemctl enable --now docker || true
      else
        echo "Install Docker for your distro: https://docs.docker.com/engine/install/"
      fi
      ;;
    Darwin*)
      echo "Docker not found. Install Docker Desktop for macOS: https://docs.docker.com/desktop/install/mac/"
      ;;
    *)
      echo "Docker not found. See installation options: https://docs.docker.com/get-docker/"
      ;;
  esac
fi

if [ "$OS_NAME" = "Linux" ] && command -v getent >/dev/null 2>&1; then
  getent group docker >/dev/null 2>&1 || sudo groupadd docker || true
  sudo usermod -aG docker "$USER" || true
fi

docker ps >/dev/null 2>&1 || echo "Docker may require a new shell. Try 'newgrp docker' or re-login."


