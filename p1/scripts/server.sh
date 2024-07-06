#!/bin/bash
#sudo apt-get update
ufw disable
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -
sudo cp /var/lib/rancher/k3s/server/node-token  /vagrant/token_file