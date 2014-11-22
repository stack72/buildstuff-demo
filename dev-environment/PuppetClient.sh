#!/bin/bash

echo "sudo su -" > /home/vagrant/.bash_profile

domain='vagrant.local'
aptSource=`cat /etc/*-release | grep DISTRIB_CODENAME | sed s/DISTRIB_CODENAME=//g`

sed -i "s/domain .*/domain $domain/g" /etc/resolv.conf
sed -i "s/search .*/search $domain/g" /etc/resolv.conf

if [ `cat /etc/rc.local | grep "domain $domain" | wc -l` -eq 0 ]; then
  sed -i "/^exit 0$/i\sed -i \"s/domain .*/domain $domain/g\" /etc/resolv.conf" /etc/rc.local
fi

if [ `cat /etc/rc.local | grep "search $domain" | wc -l` -eq 0 ]; then
  sed -i "/^exit 0$/i\sed -i \"s/search .*/search $domain/g\" /etc/resolv.conf" /etc/rc.local
fi

if [ ! -f "/etc/apt/sources.list.d/puppetlabs.list" ]; then
  echo "Creating /etc/apt/sources.list.d/puppetlabs.list"
  cat <<EOF > /etc/apt/sources.list.d/puppetlabs.list
# Puppetlabs products
deb http://apt.puppetlabs.com $aptSource main
deb-src http://apt.puppetlabs.com $aptSource main

# Puppetlabs dependencies
deb http://apt.puppetlabs.com $aptSource dependencies
deb-src http://apt.puppetlabs.com $aptSource dependencies

# Puppetlabs devel (uncomment to activate)
# deb http://apt.puppetlabs.com $aptSource devel
# deb-src http://apt.puppetlabs.com $aptSource devel
EOF
fi

apt-key add /vagrant/puppetlabs.gpg

apt-get update -y

puppet_version='3.7.1*'
apt-get install -y \
  puppet="$puppet_version" \
  puppet-common="$puppet_version"

if [ ! $? -eq 0 ]; then
  exit $?
fi

apt-get install -y ruby-bundler
apt-get install -y git

if  [[ ! "$aptSource" == "trusty" ]];
 then
    apt-get install -y rubygems
fi

hostname=`hostname | awk '{ print tolower($0) }'`
echo "Configure puppet.conf"
cat <<EOF > /etc/puppet/puppet.conf
[main]
server=master.vagrant.local
certname=$hostname.vagrant.local
pluginsync=true
autoflush=true
environment=vagrant
EOF

