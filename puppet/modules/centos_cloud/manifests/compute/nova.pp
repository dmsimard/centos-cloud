class centos_cloud::compute::nova (
  $cpu_allocation_ratio  = '1.0',
  $disk_allocation_ratio = '1.1',
  $ram_allocation_ratio  = '1.1',
  $neutron_password      = 'neutron',
  $password              = 'nova',
  $password_api          = 'nova_api',
  $reserved_host_memory  = '1024'
) {

  include centos_cloud::params

  $transport_url = os_transport_url({
    'host'      => $::centos_cloud::params::controller,
    'password'  => $password,
    'port'      => '5672',
    'transport' => 'rabbit',
    'username'  => 'nova'
  })

  class { '::nova':
    api_database_connection       => "mysql+pymysql://nova_api:${password_api}@${::centos_cloud::params::controller}/nova_api?charset=utf8",
    database_connection           => "mysql+pymysql://nova:${password}@${::centos_cloud::params::controller}/nova?charset=utf8",
    placement_database_connection => "mysql+pymysql://nova_placement:${password}@${::centos_cloud::params::controller}/nova_placement?charset=utf8",
    cpu_allocation_ratio          => $cpu_allocation_ratio,
    default_transport_url         => $transport_url,
    disk_allocation_ratio         => $disk_allocation_ratio,
    glance_api_servers            => "http://${::centos_cloud::params::controller}:9292",
    notification_driver           => 'messagingv2',
    notify_on_state_change        => 'vm_and_task_state',
    ram_allocation_ratio          => $ram_allocation_ratio
  }

  class { '::nova::placement':
    auth_url => "http://${::centos_cloud::params::controller}:35357",
    password => $password,
  }

  class { '::nova::compute':
    force_config_drive          => true,
    instance_usage_audit        => true,
    instance_usage_audit_period => 'hour',
    reserved_host_memory        => $reserved_host_memory,
    vnc_enabled                 => true
  }

  include ::nova::cell_v2::discover_hosts

  Class['nova::compute'] ~> Class['nova::cell_v2::discover_hosts']

  class { '::nova::compute::libvirt':
    libvirt_virt_type => 'kvm',
    migration_support => true,
    vncserver_listen  => '0.0.0.0'
  }

  class { '::nova::compute::neutron':
    libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'
  }

  class { '::nova::network::neutron':
    firewall_driver  => 'nova.virt.firewall.NoopFirewallDriver',
    neutron_auth_url => "http://${::centos_cloud::params::controller}:35357/v3",
    neutron_url      => "http://${::centos_cloud::params::controller}:9696",
    neutron_password => $neutron_password
  }

  include ::nova::vncproxy
  include ::nova::consoleauth
}
