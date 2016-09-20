# -*- mode: ruby -*-
# vi: set ft=ruby :

$BASE_BOX = "eval-win2012r2-standard-nocm-1.0.4"
Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |vb|
#    vb.gui = false
  end

  config.vm.define "dc" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'dc'

    config.vm.network "private_network", ip: "192.168.100.10", mac: "080027000010"

    config.vm.provision "shell", path: "provision/00_admin_password.ps1"
    config.vm.provision "shell", path: "provision/01_install_AD.ps1"
    config.vm.provision "shell", path: "provision/02_install_forest.ps1"
    config.vm.provision "shell", path: "provision/03_install_adfs.ps1"
  end

  config.vm.define "client" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'client'

    config.vm.network "private_network", ip: "192.168.100.11", mac: "080027000011"
    config.vm.provision "shell", path: "provision/06_client_setup.ps1"
  end
end
