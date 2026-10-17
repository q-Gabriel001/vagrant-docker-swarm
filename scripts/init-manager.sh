#!/usr/bin/env bash
# Inicializa o Swarm no master e publica o token de worker na pasta compartilhada.
# Uso: init-manager.sh <IP_DO_MASTER>
set -euo pipefail

MASTER_IP="${1:?informe o IP do master}"
TOKEN_FILE="/vagrant/.worker_token"

if docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "[manager] Swarm ja esta ativo."
else
  echo "[manager] inicializando Swarm em ${MASTER_IP}..."
  docker swarm init --advertise-addr "${MASTER_IP}"
fi

docker swarm join-token -q worker > "${TOKEN_FILE}"
echo "[manager] token de worker salvo em ${TOKEN_FILE}"
