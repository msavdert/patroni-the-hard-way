Vagrant.configure("2") do |config|
  config.vm.box = "cloud-image/ubuntu-24.04"
  config.vm.box_version = "20250430.0.0"

  # Basic VirtualBox configuration
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end

  # Provisioning script to install SSH, enable root login, and set root password
  config.vm.provision "shell", inline: <<-SHELL
    # Install SSH service
    apt-get update
    apt-get install -y openssh-server

    # Enable root SSH login
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

    # Set root password
    echo "root:root" | chpasswd

    # Restart SSH service
    systemctl restart ssh
  SHELL

  # Jumpbox - Management server
  config.vm.define "jumpbox" do |jumpbox|
    jumpbox.vm.hostname = "jumpbox"
    jumpbox.vm.network "private_network", ip: "192.168.56.10"
    jumpbox.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end
  end

  # HAProxy - Load Balancer
  config.vm.define "haproxy" do |haproxy|
    haproxy.vm.hostname = "haproxy"
    haproxy.vm.network "private_network", ip: "192.168.56.20"
    haproxy.vm.provider "virtualbox" do |vb|
      vb.memory = "512"
      vb.cpus = 1
    end
  end

  # 3 Patroni, PostgreSQL and etcd nodes
  (0..2).each do |i|
    config.vm.define "node-#{i}" do |node|
      node.vm.hostname = "node-#{i}"
      node.vm.network "private_network", ip: "192.168.56.#{30 + i}"
      node.vm.provider "virtualbox" do |vb|
        vb.memory = "1024"
        vb.cpus = 1
      end
    end
  end
end