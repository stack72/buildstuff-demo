## Dependencies

* [Vagrant 1.7.2](http://www.vagrantup.com/download-archive/v1.7.2.html)
* [VirtualBox 4.3.10](https://www.virtualbox.org/wiki/Download_Old_Builds_4_3)

## Usage

To use the development environment:

#### PuppetMaster

```
cd dev-environment
vagrant up --provider=virtualbox
```

This will bring up a PuppetMaster server that has a PuppetDB built into it. If you need to see the PuppetDB dashboard then go to http://172.16.0.2:8080/dashboard/index.html in your browser


#### Ubuntu Hosts

```
cd dev-environment/ubuntu
vagrant up --provider=virtualbox
```

This will bring up a single Ubuntu Trusty 14.04 host. We can ssh this host as follows:

```
cd dev-environment/ubuntu
vagrant ssh
```

When in the host, we can make sure that it can communicate with the PuppetMaster with the following commands:

```
puppet agent --enable
puppet agent -t
```

This node will then be able to communicate freely with the PuppetMaster

#### Bringing Up A Multi Node Environment

In the root of the repository is a file vagrant.yml

This file allows us to define the characteristics of the environment in yaml and without the need to change the individual Vagrantfiles

To define a number of Ubuntu nodes we would change the vagrant.yml file as follows:

```
ubuntu:
   number_of_boxes: 2
```

This would instruct vagrant to bring up 2 Ubuntu nodes named:

* Ubuntu2
* Ubuntu3

To ssh into the nodes we would use the name i.e.

```
vagrant ssh Ubuntu2
```
