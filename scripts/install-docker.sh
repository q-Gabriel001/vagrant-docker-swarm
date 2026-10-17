#!/usr/bin/env bash
# Instala o Docker Engine (script oficial) e libera o uso para o usuario vagrant.
set -euo pipefail

if command -v docker >/dev/null 2>&1; then
  echo "[docker] ja instalado: $(docker --version)"
else
  echo "[docker] instalando..."
  apt-get update -y
  apt-get install -y curl ca-certificates
  curl -fsSL https://get.docker.com | sh
fi

systemctl enable --now docker
usermod -aG docker vagrant
echo "[docker] pronto: $(docker --version)"
