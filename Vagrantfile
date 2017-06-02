# -*- mode: ruby -*-
# vi: set ft=ruby :

#VM environment option :virtualbox || :parallels
VM = :virtualbox

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  if VM == :virtualbox
    config.vm.box= "ubuntu/trusty64"
    #config.vm.box_url = "https://github.com/kraksoft/vagrant-box-ubuntu/releases/download/14.04/ubuntu-14.04-amd64.box"	
    #config.vm.box_url = 'https://github.com/sepetrov/trusty64/releases/download/v0.0.5/trusty64.box'
    config.vm.provider "virtualbox" do |v|
      v.memory = 8192
      # v.gui = true
    end
  end

  if VM == :parallels
    config.vm.box_url = "https://atlas.hashicorp.com/parallels/boxes/ubuntu-14.04"
    config.vm.box = "parallels/ubuntu-14.04"
    config.vm.provider "parallels" do |v|
      v.memory = 8192
      v.cpus = 4
      v.update_guest_tools = true
    end
  end

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :private_network, ip: "10.211.55.13"


  #config.vm.network :public_network, ip: "10.211.55.13"
  #config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest: 3000, host: 3000 #, host_ip: "127.0.0.1"
  config.vm.network :forwarded_port, guest: 4000, host: 4000 #, host_ip: "127.0.0.1"

  if VM == :parallels
    config.vm.network :forwarded_port, guest: 2222, host: 22
    config.ssh.host = '10.211.55.14'
    config.ssh.port = 22
  end

  if VM == :virtualbox
    config.ssh.host = '127.0.0.1'
    #config.vm.network :forwarded_port, guest: 2222, host: 22    
    #config.ssh.port = 2222
  end

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # Required for NFS to work, pick any local IP
  # config.vm.network :private_network, ip: "10.211.55.5"

  # Use NFS for shared folders for better performance
  config.vm.synced_folder '.', '/vagrant' #, nfs: true

  # config.vm.synced_folder ".", "/vagrant", type: "rsync",
  #   rsync__exclude: [".git/", "node_modules/"]

  config.vm.provision :ansible do |ansible|
    ansible.playbook = "zansible/install.yml"
    ansible.inventory_path = "zansible/hosts/development"
    ansible.limit = 'all'
    
    # the Vagrant VM will be put in this host group change this should
    # match the host group in your playbook you want to test
    #ansible.hosts = "ubuntu"
    if VM == :parallels
      ansible.extra_vars = { 
        ansible_ssh_host: config.ssh.host
      }
      ansible.verbose = 'vvvv'
    end

    if VM == :virtualbox
      ansible.extra_vars = { 
        ansible_ssh_host: config.ssh.host,
        ansible_ssh_port: 2222
      }
      ansible.verbose = 'vvvv'
    end

  end
end
