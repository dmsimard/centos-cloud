class centos_cloud::controller::glance (
  $backend           = 'file',
  $password          = 'glance',
  $stores            = ['http', 'file'],
  $workers           = '8',
) {

  include centos_cloud::params

  rabbitmq_user { 'glance':
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq']
  }

  rabbitmq_user_permissions { 'glance@/':
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
    'username'  => 'glance'
  })

  class { '::glance::db::mysql':
    allowed_hosts => [
      $::centos_cloud::params::controller,
      $::centos_cloud::params::allowed_hosts
    ],
    password => $password,
  }

  include ::glance
  include ::glance::client
  include ::glance::backend::file

  class { '::glance::keystone::auth':
    admin_url    => "http://${::centos_cloud::params::controller}:9292",
    internal_url => "http://${::centos_cloud::params::controller}:9292",
    public_url   => "http://${::centos_cloud::params::controller}:9292",
    password     => $password
  }

  class { '::glance::api::authtoken':
    auth_uri            => "http://${::centos_cloud::params::controller}:5000",
    auth_url            => "http://${::centos_cloud::params::controller}:35357",
    memcached_servers   => $::centos_cloud::params::memcached_servers,
    password            => $password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default'
  }

  class { '::glance::api':
    bind_host           => '0.0.0.0',
    database_connection => "mysql+pymysql://glance:${password}@${::centos_cloud::params::controller}/glance?charset=utf8",
    default_store       => $backend,
    enable_v1_api       => false,
    enable_v2_api       => true,
    registry_host       => $::centos_cloud::params::controller,
    stores              => $stores,
    workers             => $workers
  }

  class { '::glance::notify::rabbitmq':
    default_transport_url => $transport_url,
    notification_driver   => 'messagingv2'
  }
}
