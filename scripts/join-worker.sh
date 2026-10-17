#!/usr/bin/env bash
# Aguarda o token do master e entra no cluster como worker.
# Uso: join-worker.sh <IP_DO_MASTER>
set -euo pipefail

MASTER_IP="${1:?informe o IP do master}"
TOKEN_FILE="/vagrant/.worker_token"

if docker info 2>/dev/null | grep -q "Swarm: active"; then
  echo "[worker] $(hostname) ja faz parte do cluster."
  exit 0
fi

echo "[worker] aguardando token do master..."
for _ in $(seq 1 30); do
  [ -s "${TOKEN_FILE}" ] && break
  sleep 2
done

[ -s "${TOKEN_FILE}" ] || { echo "[worker] token nao encontrado." >&2; exit 1; }

docker swarm join --token "$(cat "${TOKEN_FILE}")" "${MASTER_IP}:2377"
echo "[worker] $(hostname) entrou no cluster."
