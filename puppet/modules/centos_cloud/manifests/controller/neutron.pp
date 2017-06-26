class centos_cloud::controller::neutron (
  $password                    = 'neutron',
  $nova_password               = 'nova',
  $api_workers                 = '8',
  $rpc_workers                 = '8',
  $physical_interface_mappings = ['physnet0:eth0']
) {

  include centos_cloud::params

  rabbitmq_user { 'neutron':
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq']
  }

  rabbitmq_user_permissions { 'neutron@/':
    configure_permission => '.*',
    provider             => 'rabbitmqctl',
    read_permission      => '.*',
    require              => Class['::rabbitmq'],
    write_permission     => '.*'
  }

  Rabbitmq_user_permissions['neutron@/'] -> Service<| tag == 'neutron-service' |>

  $transport_url = os_transport_url({
    'host'      => $::centos_cloud::params::controller,
    'password'  => $password,
    'port'      => '5672',
    'transport' => 'rabbit',
    'username'  => 'neutron'
  })

  class { '::neutron::db::mysql':
    allowed_hosts => [
      $::centos_cloud::params::controller,
      $::centos_cloud::params::allowed_hosts
    ],
    password => $password,
  }

  class { '::neutron::keystone::auth':
    admin_url    => "http://${::centos_cloud::params::controller}:9696",
    internal_url => "http://${::centos_cloud::params::controller}:9696",
    public_url   => "http://${::centos_cloud::params::controller}:9696",
    password     => $password
  }

  class { '::neutron':
    allow_overlapping_ips   => false,
    bind_host               => '0.0.0.0',
    core_plugin             => 'ml2',
    default_transport_url   => $transport_url,
    dhcp_agent_notification => true
  }

  include ::neutron::client

  class { '::neutron::keystone::authtoken':
    auth_uri            => "http://${::centos_cloud::params::controller}:5000",
    auth_url            => "http://${::centos_cloud::params::controller}:35357",
    memcached_servers   => $::centos_cloud::params::memcached_servers,
    password            => $password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default'
  }

  class { '::neutron::server':
    api_workers         => $api_workers,
    database_connection => "mysql+pymysql://neutron:${password}@${::centos_cloud::params::controller}/neutron?charset=utf8",
    rpc_workers         => $rpc_workers,
    sync_db             => true
  }

  class { '::neutron::server::notifications':
    auth_url => "http://${::centos_cloud::params::controller}:35357",
    password => $nova_password
  }

  class { '::neutron::plugins::ml2':
    flat_networks        => ['physnet0'],
    mechanism_drivers    => ['linuxbridge'],
    tenant_network_types => [],
    type_drivers         => ['flat']
  }

  class { '::neutron::agents::ml2::linuxbridge':
    firewall_driver             => 'neutron.agent.firewall.NoopFirewallDriver',
    local_ip                    => $::ipaddress,
    physical_interface_mappings => $physical_interface_mappings,
  }
}
