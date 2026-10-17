#!/usr/bin/env bash
# Faz o deploy da stack de demonstracao (rodar no host).
set -euo pipefail

STACK_NAME="${1:-demo}"

echo "== Deploy da stack '${STACK_NAME}' =="
vagrant ssh master -c "docker stack deploy -c /vagrant/stack/docker-compose.yml ${STACK_NAME}"

echo "== Aguardando as replicas =="
sleep 20

echo "== Servicos =="
vagrant ssh master -c "docker stack services ${STACK_NAME}"

echo "== Distribuicao das replicas =="
vagrant ssh master -c "docker stack ps ${STACK_NAME}"

echo "== Volume NFS =="
vagrant ssh master -c "docker volume ls | grep dados || true"

echo "== Acesse: http://192.168.56.10:8080 =="
echo "Para remover: vagrant ssh master -c 'docker stack rm ${STACK_NAME}'"
