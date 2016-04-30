# -*- mode: ruby -*-
# vi: set ft=ruby :

$BASE_BOX = "eval-win2012r2-standard-nocm-1.0.4"
#$BASE_BOX = "eval-win10x64-enterprise-ssh-nocm-1.0.4"
Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |vb|
#    vb.gui = false
     vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
  end

  config.vm.define "dc01" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'dc01'

    config.vm.network "public_network", bridge: "vmnet1", ip: "172.16.124.50"

    config.vm.provision "shell", path: "provision/00_admin_password.ps1"
    config.vm.provision "shell", path: "provision/01_install_AD.ps1"
    config.vm.provision "shell", path: "provision/02_install_forest.ps1"
    config.vm.provision "shell", path: "provision/03_install_adfs.ps1"
    config.vm.provision "shell", path: "provision/04_populate_AD.ps1"

    config.vm.synced_folder "/Volumes/EXT/Downloads", "/downloads"
  end

  config.vm.define "web01" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'web01'

    config.vm.network "public_network", bridge: "vmnet1", ip: "172.16.124.51"
    
    config.vm.provision "shell", path: "provision/06_join_domain.ps1", \
        args: ["172.16.124.*", "172.16.124.50"]
    config.vm.provision "shell", path: "provision/07_install_iis.ps1"

    config.vm.synced_folder "/Volumes/EXT/Downloads", "/downloads"
  end
end
