#!/bin/bash
cwd=$(cd `dirname $0` && pwd -P)
# Where OpenStack puppet modules are actually installed from packages
MODULEPATH="/usr/share/openstack-puppet/modules"

# This script will do the basic common stuff needed everywhere
if rpm -q NetworkManager; then
    service NetworkManager stop
    yum -y remove Network\*
    service network restart
fi

if rpm -q firewalld; then
    yum -y remove firewalld
fi

ping -c 3 8.8.8.8 > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo 'We lost network, exiting now'
  exit 1
fi

# Add own fqdn to hosts file
if ! grep -q "127.0.0.1 $(hostname -f)" /etc/hosts; then
    echo "127.0.0.1 $(hostname -f)" >>/etc/hosts
    echo "Added to hosts file: 127.0.0.1 $(hostname -f)"
fi

yum -y install yum-plugin-priorities centos-release-openstack-ocata
yum -y install puppet python-openstackclient openstack-selinux lvm2

# Install OpenStack puppet modules
yum -y install puppet-keystone puppet-glance puppet-neutron puppet-nova \
               puppet-openstacklib puppet-openstack_extras puppet-oslo

# Install "external" puppet modules
yum -y install puppet-apache puppet-concat puppet-inifile puppet-kmod \
               puppet-memcached puppet-mysql puppet-ntp puppet-rabbitmq \
               puppet-staging puppet-stdlib puppet-sysctl

# Storage
systemctl enable --now lvm2-lvmetad

# Install overlay module
cp -a ${cwd}/puppet/modules/centos_cloud ${MODULEPATH}/

# Install hiera configuration files
cp -a ${cwd}/puppet/hiera.yaml /etc/puppet/
ln -sf /etc/puppet/hiera.yaml /etc/hiera.yaml
cp -a ${cwd}/puppet/hiera /etc/puppet/
