#!/bin/bash
ufw disable
sudo apt-get install net-tools
URL="https://192.168.56.110:6443"
TOKEN=$(sudo cat /vagrant/token_file)
echo $URL
echo $TOKEN 
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" K3S_URL=$URL K3S_TOKEN=$TOKEN sh -