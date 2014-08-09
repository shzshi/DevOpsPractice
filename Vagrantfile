# -*- mode: ruby -*-
# vi: set ft=ruby :

boxes = [
  { :name => :web,:role => 'web_dev',:ip => '192.168.33.2',:ssh_port => 2201,:http_fwd => 8888,:https_fwd => 8086,:shares => true }
]

Vagrant::Config.run do |config|

  # Enable the Puppet provisioner, with will look in manifests
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "default.pp"
    puppet.module_path = "modules"
  end
 
  boxes.each do |opts|
    config.vm.define opts[:name] do |config|
    config.vm.box        = "centos-65-i386-virtualbox-puppet"
    config.vm.box_url    = "http://puppet-vagrant-boxes.puppetlabs.com/centos-65-i386-virtualbox-puppet.box"
    #config.vm.customize  ["modifyvm", :id, "--memory", 1024]
    #todo make this an option
 
    config.vm.forward_port  80, opts[:http_fwd],auto_correct: true if opts[:http_fwd]
    config.vm.forward_port  3306, opts[:mysql_fwd] if opts[:mysql_fwd]
	
    config.vm.network       :hostonly, opts[:ip]
    config.vm.host_name =   "%s.vagrant" % opts[:name].to_s
 
    config.vm.share_folder "../", "/home/vagrant/", "../", :nfs => false
    config.vm.forward_port  22, opts[:ssh_port], :auto => true

    end
 
  end
end