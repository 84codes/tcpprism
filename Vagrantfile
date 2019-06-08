# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  config.vm.box = "ubuntu/xenial64"
  config.vm.provision "shell", inline: <<~SHELL
      apt-key adv --keyserver keys.gnupg.net --recv-keys 09617FD37CC06B54
      echo "deb https://dist.crystal-lang.org/apt crystal main" > /etc/apt/sources.list.d/crystal.list
      apt-get update
      apt-get upgrade -y
      apt-get install -y crystal help2man lintian musl-tools
  SHELL
end
