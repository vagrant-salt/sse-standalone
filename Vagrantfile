require 'json'

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version '>= 1.6.0'
VAGRANTFILE_API_VERSION = '2'

proxy = ''
domain = 'test.local'
saltEnterpriseInstaller = 'SaltStack_Enterprise_5.5_Installer.tar.gz'

vm = { :hostname => "sse", :ip => "192.168.0.100", :box => "geerlingguy/centos7", :ram => 2048 }

# Important!
# 1. The saltEnterpriseInstaller file must already exist in the local vagrant folder, before you can run 'vagrant up'
#    You can retrieve it from the official SaltStack enterprise website, from the 'support' section
#    The exact version used to test these scripts was 'SaltStack_Enterprise_5.5_Installer.tar.gz'
# 2. If you are not using proxy, set the 'proxy' parameter up-top to an empty string. Otherwise, set it to a string like: http://proxy.local

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
   config.vm.define vm[:hostname] do |nodeconfig|
      nodeconfig.vm.provider :virtualbox do |box|
         box.name = vm[:hostname]
         box.customize [
            "modifyvm", :id,
            "--cpuexecutioncap", "50",
            "--memory", vm[:ram],
            "--cpus", "2",
         ]
      end
      fqdn = "#{vm[:hostname]}.#{domain}"
      #nodeconfig.vm.synced_folder ".", "/vagrant", disabled: true
      nodeconfig.vm.box = vm[:box]
      nodeconfig.vm.hostname = fqdn
      # enable port forwarding on the raas VM so that the web ui can be accessed from your host using the url: https://localhost
      nodeconfig.vm.network "forwarded_port", guest: 443, host: 4443, host_ip: "127.0.0.1"
      nodeconfig.vm.boot_timeout = 300
      # execute vm bootstrap
      nodeconfig.vm.provision "shell", path: "scripts/bootstrap.sh", args: [fqdn, proxy]
      # extract sse installer files and copy the pillar and salt files into /srv/
      nodeconfig.vm.provision "shell", inline: "tar -xvf /vagrant/#{saltEnterpriseInstaller} -C /"
      nodeconfig.vm.provision "shell", inline: "rm -rf /srv/ && mv /sse_installer/ /srv/"
      # also copy the modified pillar top.sls and sse_settings.yml, overwriting the existing ones
      nodeconfig.vm.provision "shell", inline: "yes | cp -f /vagrant/pillar-data/top.sls /srv/pillar/top.sls"
      nodeconfig.vm.provision "shell", inline: "yes | cp -f /vagrant/pillar-data/sse_settings.yaml /srv/pillar/sse/sse_settings.yaml"
      # install salt master and salt minion
      nodeconfig.vm.provision "shell", path: "scripts/setup-salt-master.sh", args: [fqdn, fqdn]
      # accept salt minion key
      nodeconfig.vm.provision "shell", inline: "sudo salt-key -A -y"
      # wait for minion(s) to become responsive
      nodeconfig.vm.provision "shell", inline: "echo '@@ Wait for minion services to be ready ..'"
      nodeconfig.vm.provision "shell", path: "scripts/wait-for-minion.sh", args: ['*', 30, 10]
      # refresh pillar data on all minions
      nodeconfig.vm.provision "shell", inline: "echo '@@ Refresh pillar data ..'"
      nodeconfig.vm.provision "shell", inline: "sudo salt '*' saltutil.refresh_pillar"
      # run highstate - it my need to run a few times before it completes successfully
      # I believe it is because of json parsing in the first few runs, but I haven't investigated further
      nodeconfig.vm.provision "shell", inline: "echo '@@ running highstate ..'"
      nodeconfig.vm.provision "shell", path: "scripts/run-salt-highstate.sh", args: [fqdn, 5, 5]
#      nodeconfig.vm.provision "shell", inline: "salt-call --local service.restart salt-master"
   end
end
