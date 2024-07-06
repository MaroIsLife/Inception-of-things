curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--node-ip 192.168.56.110" sh -

sudo kubectl apply -f /vagrant/confs/app1.yml
sudo kubectl apply -f /vagrant/confs/app2.yml
sudo kubectl apply -f /vagrant/confs/app3.yml
sudo kubectl apply -f /vagrant/confs/ingress.yml
