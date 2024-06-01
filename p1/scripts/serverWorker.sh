#!/bin/bash
sudo apt-get update
URL="https://192.168.56.110:6443"
sudo cat /home/tokens/token_file
TOKEN=$(sudo cat /vagrant/tokens/token_file)
echo $URL
echo $TOKEN 
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent" K3S_URL=$URL K3S_TOKEN=$TOKEN sh -