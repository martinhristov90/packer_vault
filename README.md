### This repository provides Hashicorp Packer setup to build a Vagrant box with Vault installed, integrate it with Systemd and finally to upload it to VagrantCloud.

#### How to use it :

- Execute `git clone git@github.com:martinhristov90/packerVault.git`.
- Export the env variable named `VAGRANT_CLOUD_TOKEN` with your VagrantCloud token in it. The token can be generated by visiting [this](https://app.vagrantup.com/settings/security) link.
- Substitute in the `template.json` field where it says YOUR_VAGRANTCLOUD_NAME.
- Execute `packer build template.json` to start the building process.
- Now you should have new box in VagrantCloud with Vault installed.


#### N.B : 
- Before starting the build process create an empty box in VagrantCloud with name `vault`, for example `YOUR_VAGRANTCLOUD_NAME/vault`, this is a workaround, otherwise you are going to get an error in uploading the box to VagrantCloud.
- The machine automatically exposes tcp/udp ports 8200 and 8201 to your host machine.