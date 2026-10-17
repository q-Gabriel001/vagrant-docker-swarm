# Cluster Docker Swarm com Vagrant e NFS

Infraestrutura como código para subir, com um único comando, um cluster **Docker Swarm** de 4 nós (1 manager + 3 workers) usando **Vagrant** e **VirtualBox**, com **armazenamento compartilhado via NFS** e uma stack de demonstração.

## Objetivo

Automatizar a criação de um ambiente local de orquestração de containers, sem nenhuma configuração manual:

- 4 máquinas virtuais definidas em um único `Vagrantfile`
- IP fixo para cada VM
- Docker instalado automaticamente em todas as VMs
- `master` configurado como **manager** do Swarm
- `node01`, `node02` e `node03` adicionados como **workers**
- Servidor **NFS** no master para volumes compartilhados entre os nós
- Stack `docker-compose.yml` de exemplo usando um volume NFS

## Arquitetura

```
                 Rede privada 192.168.56.0/24

   +-----------------------+
   |        master         |  192.168.56.10
   |  Swarm manager        |
   |  Servidor NFS         |  exporta /srv/nfs/dados
   +-----------+-----------+
               |
       +-------+--------+----------------+
       |                |                |
  +----+-----+    +-----+----+    +------+---+
  |  node01  |    |  node02  |    |  node03  |
  | .56.11   |    | .56.12   |    | .56.13   |
  | (worker) |    | (worker) |    | (worker) |
  +----------+    +----------+    +----------+
      Todos montam o volume NFS do master
```

| VM     | IP             | Papel                  |
|--------|----------------|------------------------|
| master | 192.168.56.10  | Manager + servidor NFS |
| node01 | 192.168.56.11  | Worker                 |
| node02 | 192.168.56.12  | Worker                 |
| node03 | 192.168.56.13  | Worker                 |

## Tecnologias

Vagrant, VirtualBox, Ubuntu 22.04 (`ubuntu/jammy64`), Docker Engine, Docker Swarm, NFS, Docker Compose (stack), Bash.

## Pré-requisitos

- [Vagrant](https://developer.hashicorp.com/vagrant/downloads)
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
- ~4 GB de RAM livres (1 GB por VM)

## Como usar

```bash
git clone https://github.com/q-Gabriel001/vagrant-docker-swarm.git
cd vagrant-docker-swarm

vagrant up
```

Verificar o cluster:

```bash
vagrant ssh master -c "docker node ls"
```

Saída esperada: `master` como `Leader` e os três nodes com status `Ready`.

### Subindo um container simples

```bash
vagrant ssh master
docker run -d --name teste -p 8082:80 nginx
```

### Subindo um serviço no Swarm

```bash
./scripts/test-cluster.sh
```

Cria um serviço `nginx` com 4 réplicas distribuídas entre os nós, acessível em `http://192.168.56.10:8081`.

### Stack com volume NFS compartilhado

```bash
./scripts/deploy-stack.sh
```

O script faz o deploy de `stack/docker-compose.yml`: um `nginx` com 4 réplicas, todas montando o mesmo volume NFS exportado pelo master. A página fica em `http://192.168.56.10:8080`.

**Provando que o volume é compartilhado:** altere o arquivo direto no servidor NFS e veja a mudança refletida em todas as réplicas, independentemente do nó:

```bash
vagrant ssh master -c "echo '<h1>Atualizado via NFS</h1>' > /srv/nfs/dados/index.html"

curl http://192.168.56.10:8080
curl http://192.168.56.11:8080
curl http://192.168.56.13:8080
```

Remover a stack:

```bash
vagrant ssh master -c "docker stack rm demo"
```

### Comandos úteis

| Comando | Descrição |
|---------|-----------|
| `vagrant status` | Estado das VMs |
| `vagrant ssh master` | Acessa o manager |
| `vagrant halt` | Desliga as VMs |
| `vagrant destroy -f` | Remove tudo |
| `vagrant provision` | Reexecuta o provisionamento |

## Como funciona

O `Vagrantfile` percorre um mapa de máquinas e aplica os *provisioners* em cada uma:

1. **`install-docker.sh`** (todas): instala o Docker via script oficial e libera o usuário `vagrant` no grupo `docker`.
2. **`setup-nfs-client.sh`** (todas): instala o `nfs-common`, necessário para montar volumes NFS.
3. **`setup-nfs-server.sh`** (master): instala o `nfs-kernel-server` e exporta `/srv/nfs/dados` para a sub-rede do cluster.
4. **`init-manager.sh`** (master): executa `docker swarm init --advertise-addr 192.168.56.10` e grava o token de worker em `/vagrant/.worker_token` (pasta compartilhada com o host).
5. **`join-worker.sh`** (nodes): aguarda o token e executa `docker swarm join` apontando para o master na porta `2377`.

Os scripts são idempotentes: rodar `vagrant provision` novamente não quebra um cluster já configurado.

### Por que NFS?

O volume padrão do Docker (driver `local`) existe somente na máquina onde foi criado. Em um Swarm, as réplicas de um serviço rodam em nós diferentes, então cada uma teria seus próprios dados. Com um volume do tipo NFS, todos os nós montam o mesmo diretório remoto e os dados ficam consistentes, mesmo se um container for reagendado para outro nó.

## Estrutura do projeto

```
.
├── Vagrantfile
├── scripts/
│   ├── install-docker.sh
│   ├── setup-nfs-client.sh
│   ├── setup-nfs-server.sh
│   ├── init-manager.sh
│   ├── join-worker.sh
│   ├── test-cluster.sh
│   └── deploy-stack.sh
├── stack/
│   └── docker-compose.yml
├── .gitignore
├── .gitattributes
└── README.md
```

## Solução de problemas

**Erro de range de IP no VirtualBox** (Linux/macOS): crie o arquivo `/etc/vbox/networks.conf` com o conteúdo:

```
* 192.168.56.0/21
```

**Worker não entrou no cluster:** execute `vagrant provision node01` (ou o node afetado) depois que o master estiver pronto.

**Réplica não sobe por erro de montagem NFS:** confirme que o export está ativo com `vagrant ssh master -c "sudo exportfs -v"` e que o `nfs-common` está instalado no nó (`vagrant provision <nó>`).

**Scripts com erro `\r: command not found`** (Windows): o `.gitattributes` já força finais de linha LF; se o problema persistir, converta os scripts com `dos2unix`.

## Melhorias futuras

- Visualizer e monitoramento (Prometheus + Grafana)
- Múltiplos managers para alta disponibilidade
- Servidor NFS em uma VM dedicada
- Parametrizar número de nodes e recursos via variáveis de ambiente

## Autor

**Gabriel Araújo**
