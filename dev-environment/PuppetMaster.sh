#!/bin/bash

echo "sudo su -" > /home/vagrant/.bash_profile

domain='vagrant.local'
aptSource="precise"

sed -i "s/domain .*/domain $domain/g" /etc/resolv.conf
sed -i "s/search .*/search $domain/g" /etc/resolv.conf

if [ `cat /etc/rc.local | grep "domain $domain" | wc -l` -eq 0 ]; then
  sed -i "/^exit 0$/i\sed -i \"s/domain .*/domain $domain/g\" /etc/resolv.conf" /etc/rc.local
fi

if [ `cat /etc/rc.local | grep "search $domain" | wc -l` -eq 0 ]; then
  sed -i "/^exit 0$/i\sed -i \"s/search .*/search $domain/g\" /etc/resolv.conf" /etc/rc.local
fi

if [ -f "/etc/puppet/puppet.conf" ]; then
  rm /etc/puppet/puppet.conf
fi

if [ -f "/etc/puppet/puppetdb.conf" ]; then
  rm /etc/puppet/puppetdb.conf
fi

if [ -f "/etc/puppet/routes.yaml" ]; then
  rm /etc/puppet/routes.yaml
fi

apt-key add /vagrant/puppetlabs.gpg

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

apt-get update -y

puppet_version='3.7.1*'
apt-get -y --force-yes install \
  puppet="$puppet_version" \
  puppet-common="$puppet_version" \
  puppetmaster="$puppet_version" \
  puppetmaster-common="$puppet_version"

if [ ! $? -eq 0 ]; then
  exit $?
fi

apt-get install -y ruby-bundler

hostname=`hostname | awk '{ print tolower($0) }'`
echo "Configure /etc/puppet/puppet.conf for $hostname"
cat <<EOF > /etc/puppet/puppet.conf
[main]
server=$hostname.$domain
certname=$hostname.$domain
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=\$vardir/lib/facter
templatedir=\$confdir/templates
modulepath=\$confdir/otmodules:\$confdir/modules

[agent]
environment=vagrant
EOF

cat <<EOF > /etc/puppet/autosign.conf
*.$domain
EOF

if [ ! -f /etc/puppet/manifests/nodes.pp ]; then
echo "Configure puppet nodes.pp"
cat <<EOF > /etc/puppet/manifests/nodes.pp
node default { }


EOF
fi

if [ ! -f /etc/puppet/manifests/site.pp ]; then
echo "Configure puppet site.pp"
cat <<EOF > /etc/puppet/manifests/site.pp
import 'nodes'
EOF
fi

apt-get install -y git
if [ ! $? -eq 0 ]; then
  exit $?
fi

apt-get install -y rubygems
if [ ! $? -eq 0 ]; then
  exit $?
fi

curDir=`pwd`

cd /etc/puppet

echo "Running bundle install"
bundle install
if [ ! $? -eq 0 ]; then
  exit $?
fi

cd $curDir

if [ `cat /etc/rc.local | grep "/etc/init.d/puppetmaster start" | wc -l` -eq 0 ] && [ -f /etc/init.d/puppetmaster ]; then
  sed -i "/^exit 0$/i\/etc/init.d/puppetmaster start" /etc/rc.local
fi

/etc/init.d/puppetmaster restart
