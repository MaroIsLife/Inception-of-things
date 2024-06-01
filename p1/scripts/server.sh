#!/bin/bash
sudo apt-get update
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -
sudo cat /var/lib/rancher/k3s/server/node-token > /vagrant/tokens/token_file