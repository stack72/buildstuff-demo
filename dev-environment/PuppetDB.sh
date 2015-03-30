#!/bin/bash

# PuppetDB

domain='vagrant.local'
hostname=`hostname | awk '{ print tolower($0) }'`

cat <<EOF >> /etc/sysctl.conf

# IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

sysctl -p

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y --force-yes puppetdb
if [ ! $? -eq 0 ]; then
  exit $?
fi

apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install -y --force-yes puppetdb-terminus
if [ ! $? -eq 0 ]; then
  exit $?
fi

cat <<EOF >> /etc/puppet/puppet.conf

[master]
  reports = store, puppetdb
  storeconfigs = true
  storeconfigs_backend = puppetdb
EOF

ipaddress=`ifconfig  | grep 'inet addr:'| grep '172.16.0.' | cut -d: -f2 | awk '{ print $1}'`

cat <<EOF > /etc/puppet/puppetdb.conf
[main]
server = $hostname.$domain
port = 8081
EOF

cat <<EOF > /etc/puppet/routes.yaml
---
master:
  facts:
    terminus: puppetdb
    cache: yaml
EOF

if [ -f '/etc/puppetdb/conf.d/jetty.ini' ]; then
  sed -i "s/^ssl-host = .*$/ssl-host = $ipaddress/g" /etc/puppetdb/conf.d/jetty.ini
  sed -i "s/^# host = .*$/host = $ipaddress/g" /etc/puppetdb/conf.d/jetty.ini
fi

if [ `cat /etc/rc.local | grep "/etc/init.d/puppetdb start" | wc -l` -eq 0 ] && [ -f /etc/init.d/puppetdb ]; then
  sed -i "/^exit 0$/i\/etc/init.d/puppetdb start" /etc/rc.local
fi

/etc/init.d/puppetdb restart

rm /etc/rc?.d/*puppet*
