# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
  config.vm.box = "gitlabrunner-win2016"
  config.vm.box_url = "http://linux64-stretch-agility-1.aldebaran.lan/dav/boxes/gitlabrunner-win2016-2019-11-05.box"
  config.vm.provision "shell", path: "provision.ps1"
end
