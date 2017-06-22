#!/bin/bash
# Helper script to repetitively test things quickly

. baseline.sh
if [ $? -ne 0 ]; then
  echo 'Something broke in the baseline'
  exit 1
fi

# Add controller.openstack.home to hosts file
if ! grep -q "127.0.0.1 controller.openstack.home" /etc/hosts; then
    echo "127.0.0.1 controller.openstack.home" >>/etc/hosts
    echo "Added to hosts file: 127.0.0.1 controller.openstack.home"
fi

puppet apply --modulepath=${MODULEPATH} -e "include ::centos_cloud::controller" || exit 1

# Sanity check
source /root/openrc_admin
openstack endpoint list
if [ $? -eq 0 ]; then
  echo 'Sanity check successful!'
fi
