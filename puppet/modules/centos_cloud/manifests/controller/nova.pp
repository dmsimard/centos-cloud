class centos_cloud::controller::nova (
  $cpu_allocation_ratio  = '1.0',
  $disk_allocation_ratio = '1.1',
  $ram_allocation_ratio  = '1.1',
  $neutron_password  = 'neutron',
  $password          = 'nova',
  $password_api      = 'nova_api',
  $threads           = '1',
  $workers           = '8',
) {

  include centos_cloud::params

  rabbitmq_user { 'nova':
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq']
  }

  rabbitmq_user_permissions { 'nova@/':
    configure_permission => '.*',
    provider             => 'rabbitmqctl',
    read_permission      => '.*',
    require              => Class['::rabbitmq'],
    write_permission     => '.*'
  }

  $transport_url = os_transport_url({
    'host'      => $::centos_cloud::params::controller,
    'password'  => $password,
    'port'      => '5672',
    'transport' => 'rabbit',
    'username'  => 'nova'
  })

  class { '::nova::db::mysql':
    allowed_hosts => [
      $::centos_cloud::params::controller,
      $::centos_cloud::params::allowed_hosts
    ],
    password => $password,
  }

  class { '::nova::db::mysql_api':
    allowed_hosts => [
      $::centos_cloud::params::controller,
      $::centos_cloud::params::allowed_hosts
    ],
    password => $password_api,
  }

  class { '::nova::db::mysql_placement':
    password => $password,
  }

  class { '::nova::keystone::auth':
    admin_url    => "http://${::centos_cloud::params::controller}:8774/v2.1",
    internal_url => "http://${::centos_cloud::params::controller}:8774/v2.1",
    public_url   => "http://${::centos_cloud::params::controller}:8774/v2.1",
    password     => $password
  }

  class { '::nova::keystone::auth_placement':
    public_url   => "http://${::centos_cloud::params::controller}:8778/placement",
    internal_url => "http://${::centos_cloud::params::controller}:8778/placement",
    admin_url    => "http://${::centos_cloud::params::controller}:8778/placement",
    password     => $password,
  }

  class { '::nova::keystone::authtoken':
    auth_uri            => "http://${::centos_cloud::params::controller}:5000",
    auth_url            => "http://${::centos_cloud::params::controller}:35357",
    memcached_servers   => $::centos_cloud::params::memcached_servers,
    password            => $password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default'
  }

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

  class { '::nova::api':
    api_bind_address      => '0.0.0.0',
    enabled_apis          => ['osapi_compute'],
    install_cinder_client => true,
    osapi_compute_workers => $workers,
    sync_db_api           => true
  }

  include ::apache
  class { '::nova::wsgi::apache_placement':
    api_port  => '8778',
    bind_host => '0.0.0.0',
    ssl       => false,
    threads   => $threads,
    workers   => $workers
  }
  class { '::nova::placement':
    auth_url => "http://${::centos_cloud::params::controller}:35357",
    password => $password,
  }

  class { '::nova::network::neutron':
    firewall_driver  => 'nova.virt.firewall.NoopFirewallDriver',
    neutron_auth_url => "http://${::centos_cloud::params::controller}:35357/v3",
    neutron_url      => "http://${::centos_cloud::params::controller}:9696",
    neutron_password => $neutron_password
  }

  class { '::nova::client': }
  class { '::nova::conductor':
    workers => $workers,
  }
  include ::nova::cron::archive_deleted_rows
  include ::nova::scheduler
  include ::nova::scheduler::filter

  include ::nova::cell_v2::simple_setup
}
