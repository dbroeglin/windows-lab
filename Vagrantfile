# -*- mode: ruby -*-
# vi: set ft=ruby :

$NET_PREFIX       = "172.16.124"
$BRIDGE_IF        = "vmnet1"
$DOWNLOADS_DIR    = "/Volumes/EXT/Downloads"
$WITH_NETSCALER   = ENV['WITH_NETSCALER'] == 'true'

$DC_IP            = "#{$NET_PREFIX}.50"
$IIS_IP           = "#{$NET_PREFIX}.51"
$CLIENT_IP        = "#{$NET_PREFIX}.52"
$ADFS_IP          = "#{$NET_PREFIX}.53"
$LAB_NET_PATTERN  = "#{$NET_PREFIX}.*"
$BASE_BOX         = "windows2012r2min-wmf5-virtualbox"

Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |vb|
#     vb.gui = false
#     vb.customize ["modifyvm", :id, "--memory", "1024"]
     vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
  end

  config.vm.define "dc01" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'dc01'

    config.vm.network "public_network", bridge: $BRIDGE_IF, ip: $DC_IP

    config.vm.provision "shell", path: "provision/00_common.ps1", \
        args: [$LAB_NET_PATTERN]
    config.vm.provision "shell", path: "provision/01_install_AD.ps1"
    config.vm.provision "shell", path: "provision/02_install_forest.ps1"
    config.vm.provision "shell", path: "provision/03_populate_AD.ps1", \
        args: [$IIS_IP]
    config.vm.provision "shell", path: "provision/03_populate_AD2.ps1" if $WITH_NETSCALER
        

    config.vm.synced_folder $DOWNLOADS_DIR, "/downloads"
  end

  config.vm.define "web01" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'web01'

    config.vm.network "public_network", bridge: $BRIDGE_IF, ip: $IIS_IP
    
    config.vm.provision "shell", path: "provision/00_common.ps1", \
        args: [$LAB_NET_PATTERN]
    config.vm.provision "shell", path: "provision/06_join_domain.ps1", \
        args: [$LAB_NET_PATTERN, $DC_IP]
    config.vm.provision "shell", path: "provision/07_install_iis.ps1"

    config.vm.synced_folder $DOWNLOADS_DIR, "/downloads"
  end

  config.vm.define "client01" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'client01'

    config.vm.network "public_network", bridge: $BRIDGE_IF, ip: $CLIENT_IP
    
    config.vm.provision "shell", path: "provision/00_common.ps1", \
        args: [$LAB_NET_PATTERN]
    config.vm.provision "shell", path: "provision/06_join_domain.ps1", \
        args: [$LAB_NET_PATTERN, $DC_IP]
    config.vm.provision "shell", path: "provision/08_client.ps1"

    config.vm.synced_folder $DOWNLOADS_DIR, "/downloads"
  end

  config.vm.define "adfs01" do |config|
    config.vm.box = $BASE_BOX
    config.vm.hostname = 'adfs01'

    config.vm.network "public_network", bridge: $BRIDGE_IF, ip: $ADFS_IP

    config.vm.provision "shell", path: "provision/00_common.ps1", \
        args: [$LAB_NET_PATTERN]
    config.vm.provision "shell", path: "provision/06_join_domain.ps1", \
        args: [$LAB_NET_PATTERN, $DC_IP]
    config.vm.provision "shell", path: "provision/04_install_adfs.ps1"
    config.vm.provision "shell", path: "provision/05_populate_adfs.ps1" if $WITH_NETSCALER

    config.vm.synced_folder $DOWNLOADS_DIR, "/downloads"
  end
end
