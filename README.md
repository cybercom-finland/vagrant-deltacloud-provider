# Vagrant Deltacloud Cloud Provider

**WORK IN PROGRESS**
**This provider supports creating and destroying instances, and Deltacloud specific listing commands. Instance and volume management commands are not tested yet.**

## TODO
* Test and fix volume management commands.
* Test and fix instance management commands.
* Fix the automatic tests.
* Fix the error messages for the error situations. Now all errors give tangentially relevant stacktraces only.

## Summary

This is a [Vagrant](http://www.vagrantup.com) 1.4+ plugin that adds a
[Deltacloud](https://deltacloud.apache.org/) provider to Vagrant,
allowing Vagrant to control and provision machines within Deltacloud
cloud.

**Note:** This plugin was originally forked from [https://github.com/ggiamarchi/vagrant-openstack-provider](https://github.com/ggiamarchi/vagrant-openstack-provider)

This plugin is made to work for example with Cybercom Deltacloud API: [https://confluence.cybercom.com/display/CYBERCLOUD/Using+Cybercom+Cloud+API](https://confluence.cybercom.com/display/CYBERCLOUD/Using+Cybercom+Cloud+API)

## Features

* Create and boot Deltacloud instances
* SSH into the instances
* Provision the instances with any built-in Vagrant provisioner
* Minimal synced folder support via `rsync`

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `deltacloud` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-deltacloud-provider
...
$ vagrant up --provider=deltacloud
...
```

Of course prior to doing this, you'll need to obtain a Deltacloud-compatible
box file for Vagrant. For example here: https://github.com/cybercom-finland/vagrant-deltacloud-provider/raw/master/source/dummy.box

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to specify all the details manually within a `config.vm.provider`
block in the Vagrantfile

Create a Vagrantfile that looks like the following, filling in your information
where necessary.

This Vagrantfile shows the minimal needed configuration.

```ruby
require 'vagrant-deltacloud-provider'

Vagrant.configure('2') do |config|

  config.vm.box       = 'deltacloud'
  config.ssh.username = 'ec2-user'

  config.vm.provider :deltacloud do |os|
    os.deltacloud_api_url = 'https://standard.fi-central.cybercomcloud.com/api'
    os.username           = 'myDeltacloudUser'
    os.password           = 'myDeltacloudPassword'
    os.tenant_name        = 'myTenant'
    os.hardware_profile   = 'M-60'
    os.image              = 'ubuntu1404_qcow2_64_141105.ubuntu1404-IaaS-publish-22'
  end
end
```

And then run `vagrant up --provider=deltacloud`.

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.

## Configuration

This provider exposes quite a few provider-specific configuration options:

### Credentials

* `username` - The username with which to access Deltacloud.
* `password` - The API key for accessing Deltacloud.
* `tenant_name` - The Deltacloud project name to work on
* `deltacloud_url` - The Deltacloud endpoint.

### VM Configuration

* `server_name` - The name of the server within Deltacloud Cloud. This
  defaults to the name of the Vagrant machine (via `config.vm.define`), but
  can be overridden with this.
* `hardware_profile` - The name of the hardware_profile to use for the VM
* `image` - The name of the image to use for the VM
* `user_data` - String of User data to be sent to the newly created Deltacloud instance. Use this e.g. to inject a script at boot time.
* `metadata` - A Hash of metadata that will be sent to the instance for configuration e.g. `os.metadata  = { 'key' => 'value' }`

#### Networks

Networking features in the form of `config.vm.network` are not
supported with `vagrant-deltacloud`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the Deltacloud server.

#### Volumes

* `volumes` - Volume list that have to be attached to the server. You can provide volume id or name. However, in Deltacloud
a volume name is not unique, thus if there are two volumes with the same name in your project the plugin will fail. If so,
you have to use only ids. Optionally, you can specify the device that will be assigned to the volume.

Here comes an example that show six volumes attached to a server :

```ruby
config.vm.provider :deltacloud do |os|
 ...
os.volumes = [
  '619e027c-f4a9-493d-8c15-c89de81cb949',
  'vol-name-02',
  {
    id: '410096ff-ef71-4ca4-8006-e5bd9e99239a',
    device: '/dev/vdc'
  },
  {
    name: 'vol-name-04',
    device: '/dev/vde'
  },
  {
    name: 'vol-name-05'
  },
  {
    id: '9e419e91-8f66-4803-bc45-4600182cfd8d'
  }
]
end
```

### SSH authentication

You will most likely want to let the Vagrant provider to automatically create the key pair and publish the public key to the cloud for you. In that case, just leave out the authentication options. The following configuration options are for more complex use cases only.

* `public_key_name` - The name of the key pair register in Deltacloud to associate with the VM. The public key should
  be the matching pair for the private key configured with `config.ssh.private_key_path` on Vagrant.
* `public_key_path` - if `public_key_name` is not provided, the path to the public key will be used by vagrant to generate a public key on the Deltacloud cloud. The public key will be destroyed when the VM is destroyed.

If neither `public_key_name` nor `public_key_path` are set, vagrant will generate a new ssh key and automatically import it in Deltacloud.

* `ssh_disabled` - if set to `true`, all ssh actions managed by the provider will be disabled. We recommend to use this option only to create private VMs that won't be accessed directly from vagrant. Some actions might still want to connect with SSH (provisioners...). In this case, we will just warn you that the ssh action is likely to fail, but we won't forbid it

### Synced folders

* `sync_method` - Specify the synchronization method for shared folder between the host and the remote VM.
  Currently, it can be "rsync" or "none". The default value is "rsync". If your Deltacloud image does not
  include rsync, you must set this parameter to "none".
* `rsync_includes` - If `sync_method` is set to "rsync", this parameter give the list of local folders to sync
  on the remote VM.

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the Deltacloud provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Vagrant standard configuration

There are some standard configuration options that this provider takes into account when
creating and connecting to Deltacloud machines

* `config.vm.box` - A box is not mandatory for this provider. However, if you are running Vagrant before version 1.6, vagrant will not start
   if this property is not set. In this case you can assign any value to it. See section "Box Format" to know more about boxes.
* `config.vm.box_url` - URL of the box when it is necessary
* `ssh.username` - Username used by vagrant for SSH login
* `ssh.port` - Default SSH port is 22. If set, this option will override the default for SSH login
* `ssh.private_key_path` - If set, vagrant will use this private key path to SSH on the machine. If you set this option, the `public_key_path` option of the provider should be set.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `deltacloud` boxes. You can view an example box in
the [example_box/ directory](https://github.com/cybercom-finland/vagrant-deltacloud-provider/tree/master/source/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Custom commands

Custom commands are provided for Deltacloud. Type `vagrant deltacloud` to
show available commands.

```
$ vagrant deltacloud

Usage: vagrant deltacloud command

Available subcommands:
     image-list             List available images
     instance-list          List available instances
     hardware_profile-list  List available hardware_profiles
     network-list           List private networks in project
     volume-list            List existing volumes
     reset                  Reset Vagrant Deltacloud provider to a clear state
```

For instance `vagrant deltacloud image-list` lists images available in Glance.

```
$ vagrant deltacloud image-list

+--------------------------------------+---------------------+
| 'Id'                                 | 'Name'              |
+--------------------------------------+---------------------+
| 594f1287-9de3-4f3e-b82a-6ad223943ab2 | ubuntu-12.04_x86_64 |
| 3e5aca4a-bf12-4721-87df-7bc8fd1fc36c | debian7_x86_64      |
| 3e561121-d8d0-4328-b319-7076bfb3b18a | ubuntu-14.04_x86_64 |
| 5c576643-7ea3-49db-b1c0-9b245d955ee0 | rhel65_x86_64       |
| d3145dd5-654a-4936-b421-9333f02ae66c | centos6_x86_64      |
+--------------------------------------+---------------------+
```

## Contribute

### Development

To work on the `vagrant-deltacloud` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

Note: Vagrant 1.6 requires bundler version < 1.7. We recommend using last 1.6
version.

```
$ gem install bundler -v 1.6.8
```

Install the plugin dependencies

```
$ bundle install
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=deltacloud
```

## Troubleshooting

### Logging

To enable all Vagrant logs set environment variable `VAGRANT_LOG` to the desire
log level (for instance `VAGRANT_LOG=debug`). If you want only Deltacloud provider
logs use the variable `VAGRANT_DELTACLOUD_LOG`. if both variables are set, `VAGRANT_LOG`
takes precedence.


### CentOS/RHEL/Fedora (sudo: sorry, you must have a tty to run sudo)

The default configuration of the RHEL family of Linux distributions requires a
tty in order to run sudo. Vagrant does not connect with a tty by default, so
you may experience the error:
> sudo: sorry, you must have a tty to run sudo

The best way to take deal with this error is to upgrade to Vagrant 1.4 or
later, and enable:
```
config.ssh.pty = true
```