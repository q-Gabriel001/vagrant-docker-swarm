# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Cluster Docker Swarm com Vagrant
# 1 manager (master) + 3 workers (node01, node02, node03)
# O master tambem atua como servidor NFS (armazenamento compartilhado).

BOX        = "ubuntu/jammy64"
MASTER_IP  = "192.168.56.10"
NFS_SUBNET = "192.168.56.0/24"

MACHINES = {
  "master" => { ip: MASTER_IP,       memory: 1024, cpus: 1 },
  "node01" => { ip: "192.168.56.11", memory: 1024, cpus: 1 },
  "node02" => { ip: "192.168.56.12", memory: 1024, cpus: 1 },
  "node03" => { ip: "192.168.56.13", memory: 1024, cpus: 1 },
}

Vagrant.configure("2") do |config|
  config.vm.box = BOX

  MACHINES.each do |name, opts|
    config.vm.define name do |node|
      node.vm.hostname = name
      node.vm.network "private_network", ip: opts[:ip]

      node.vm.provider "virtualbox" do |vb|
        vb.name   = "swarm-#{name}"
        vb.memory = opts[:memory]
        vb.cpus   = opts[:cpus]
      end

      # Todas as VMs: Docker + cliente NFS
      node.vm.provision "docker", type: "shell",
        path: "scripts/install-docker.sh"
      node.vm.provision "nfs-client", type: "shell",
        path: "scripts/setup-nfs-client.sh"

      if name == "master"
        # Master: servidor NFS + Swarm manager
        node.vm.provision "nfs-server", type: "shell",
          path: "scripts/setup-nfs-server.sh", args: [NFS_SUBNET]
        node.vm.provision "swarm-manager", type: "shell",
          path: "scripts/init-manager.sh", args: [MASTER_IP]
      else
        # Nodes: entram no cluster como workers
        node.vm.provision "swarm-worker", type: "shell",
          path: "scripts/join-worker.sh", args: [MASTER_IP]
      end
    end
  end
end
