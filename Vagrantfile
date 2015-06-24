# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.



  # virtualbox box...
  ## Every Vagrant virtual environment requires a box to build off of.
  #config.vm.box = "ubuntu12"

  ## The url from where the 'config.vm.box' box will be fetched if it
  ## doesn't already exist on the user's system.
  # config.vm.box_url = "https://dl.dropboxusercontent.com/u/3403211/considerit/ubuntu12.box"

  # config.vm.provider "virtualbox" do |v|
  #   v.memory = 2048
  #   # v.gui = true
  # end

  # parallels box...
  config.vm.box_url = "https://atlas.hashicorp.com/parallels/boxes/ubuntu-14.04"
  config.vm.box = "parallels/ubuntu-14.04"
  config.vm.provider "parallels" do |v|
    v.memory = 2048
    v.cpus = 4
    v.update_guest_tools = true
  end

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 4000, host: 4000
  config.vm.network :forwarded_port, guest: 2222, host: 22

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network :hostonly, "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network :public_network

  # If true, then any SSH connections made will enable agent forwarding.
  # Default value: false
  # config.ssh.forward_agent = true

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Required for NFS to work, pick any local IP
  #config.vm.network :private_network, ip: "10.211.55.3"

  # Use NFS for shared folders for better performance
  config.vm.synced_folder '.', '/vagrant', nfs: true

  # config.vm.synced_folder ".", "/vagrant", type: "rsync",
  #   rsync__exclude: [".git/", "node_modules/"]

  #config.ssh.host = '10.211.55.4'
  config.ssh.port = 22

  config.vm.provision :ansible do |ansible|
    # point Vagrant at the location of your playbook you want to run

    #setup core
    ansible.playbook = "zansible/install-for-local-dev.yml"

    ansible.inventory_path = "zansible/hosts/development"
    ansible.limit = 'all'
    
    # the Vagrant VM will be put in this host group change this should
    # match the host group in your playbook you want to test
    #ansible.hosts = "ubuntu"

    ansible.extra_vars = { 
      ansible_ssh_host: '10.211.55.4',
    }
    ansible.verbose = 'vvvv'
  end

end
