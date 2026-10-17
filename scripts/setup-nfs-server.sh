#!/usr/bin/env bash
# Configura o master como servidor NFS e exporta /srv/nfs/dados.
# Uso: setup-nfs-server.sh <SUBREDE_CIDR>   (ex.: 192.168.56.0/24)
set -euo pipefail

SUBNET="${1:?informe a sub-rede permitida}"
EXPORT_DIR="/srv/nfs/dados"
EXPORT_LINE="${EXPORT_DIR} ${SUBNET}(rw,sync,no_subtree_check,no_root_squash)"

if ! dpkg -s nfs-kernel-server >/dev/null 2>&1; then
  echo "[nfs-server] instalando nfs-kernel-server..."
  apt-get update -y
  apt-get install -y nfs-kernel-server
fi

mkdir -p "${EXPORT_DIR}"
chmod 777 "${EXPORT_DIR}"

if [ ! -f "${EXPORT_DIR}/index.html" ]; then
  cat > "${EXPORT_DIR}/index.html" <<'HTML'
<h1>Docker Swarm + NFS</h1>
<p>Este conteudo vem de um volume NFS compartilhado entre todos os nos do cluster.</p>
HTML
fi

grep -qF "${EXPORT_LINE}" /etc/exports || echo "${EXPORT_LINE}" >> /etc/exports

exportfs -ra
systemctl enable --now nfs-kernel-server
echo "[nfs-server] exportando ${EXPORT_DIR} para ${SUBNET}"
