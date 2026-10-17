#!/usr/bin/env bash
# Teste rapido do cluster (rodar no host): sobe um servico nginx com 4 replicas.
set -euo pipefail

echo "== Nos do cluster =="
vagrant ssh master -c "docker node ls"

echo "== Criando servico de teste =="
vagrant ssh master -c "docker service rm web >/dev/null 2>&1 || true"
vagrant ssh master -c "docker service create --name web --replicas 4 -p 8081:80 nginx"
sleep 15

echo "== Distribuicao das replicas =="
vagrant ssh master -c "docker service ps web"

echo "== Acesse: http://192.168.56.10:8081 =="
echo "Para remover: vagrant ssh master -c 'docker service rm web'"
