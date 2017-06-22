class centos_cloud::controller::provision (
  $provision_images = false,
) {
  ###
  # Nova
  ###
  Keystone_user_role['admin@openstack'] -> Nova_flavor<||>

  nova_flavor { 'small':
    ensure => present,
    ram    => '1024',
    disk   => '20',
    vcpus  => 1
  }

  nova_flavor { 'medium':
    ensure => present,
    ram    => '2048',
    disk   => '30',
    vcpus  => 2
  }

  nova_flavor { 'large':
    ensure => present,
    ram    => '4096',
    disk   => '40',
    vcpus  => 4
  }

  nova_flavor { 'xlarge':
    ensure => present,
    ram    => '8192',
    disk   => '50',
    vcpus  => 8
  }

  nova_flavor { 'xxlarge':
    ensure => present,
    ram    => '16384',
    disk   => '100',
    vcpus  => 16
  }

  ###
  # Neutron
  ###
  Keystone_user_role['admin@openstack'] -> Neutron_network<||>
  Keystone_user_role['admin@openstack'] -> Neutron_subnet<||>

  neutron_network { 'publicnet':
    shared                    => true,
    provider_network_type     => 'flat',
    provider_physical_network => 'physnet0',
  }

  neutron_subnet { 'publicsubnet':
    cidr             => '172.16.0.0/24',
    gateway_ip       => '172.16.0.1',
    network_name     => 'publicnet',
    dns_nameservers  => ['8.8.8.8', '8.8.4.4'],
    allocation_pools => ['start=172.16.0.2,end=172.16.0.254'],
  }

  ###
  # Glance
  ###
  if $provision_images {
    Keystone_user_role['admin@openstack'] -> Glance_image<||>

#    glance_image { 'CentOS 7':
#      ensure           => present,
#      container_format => 'bare',
#      disk_format      => 'qcow2',
#      is_public        => 'yes',
#      source           => 'http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2'
#    }

    glance_image { 'Fedora 25':
      ensure           => present,
      container_format => 'bare',
      disk_format      => 'qcow2',
      is_public        => 'yes',
      source           => 'https://download.fedoraproject.org/pub/fedora/linux/releases/25/CloudImages/x86_64/images/Fedora-Cloud-Base-25-1.3.x86_64.qcow2'
    }

#    glance_image { 'Ubuntu 16.04':
#      ensure           => present,
#      container_format => 'bare',
#      disk_format      => 'qcow2',
#      is_public        => 'yes',
#      source           => 'https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img'
#    }
  }
}
