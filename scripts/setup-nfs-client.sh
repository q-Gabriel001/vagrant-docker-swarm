#!/usr/bin/env bash
# Instala o cliente NFS (necessario para montar volumes NFS no Docker).
set -euo pipefail

if dpkg -s nfs-common >/dev/null 2>&1; then
  echo "[nfs-client] nfs-common ja instalado."
else
  echo "[nfs-client] instalando nfs-common..."
  apt-get update -y
  apt-get install -y nfs-common
fi
