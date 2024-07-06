#!/bin/bash
#sudo apt-get update
ufw disable
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-external-ip=192.168.56.110" sh -
sudo cp /var/lib/rancher/k3s/server/node-token  /vagrant/token_file