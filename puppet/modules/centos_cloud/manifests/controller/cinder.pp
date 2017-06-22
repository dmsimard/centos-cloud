class centos_cloud::controller::cinder (
  $password = 'cinder',
  $workers  = '8',
  $threads  = '1'
) {

  include ::centos_cloud::params

  rabbitmq_user { 'cinder':
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
    require  => Class['::rabbitmq']
  }

  rabbitmq_user_permissions { 'cinder@/':
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
    'username'  => 'cinder'
  })

  class { '::cinder::db::mysql':
    password => $password,
  }

  class { '::cinder::keystone::auth':
    public_url          => "http://${::centos_cloud::params::controller}:8776/v1/%(tenant_id)s",
    internal_url        => "http://${::centos_cloud::params::controller}:8776/v1/%(tenant_id)s",
    admin_url           => "http://${::centos_cloud::params::controller}:8776/v1/%(tenant_id)s",
    public_url_v2       => "http://${::centos_cloud::params::controller}:8776/v2/%(tenant_id)s",
    internal_url_v2     => "http://${::centos_cloud::params::controller}:8776/v2/%(tenant_id)s",
    admin_url_v2        => "http://${::centos_cloud::params::controller}:8776/v2/%(tenant_id)s",
    public_url_v3       => "http://${::centos_cloud::params::controller}:8776/v3/%(tenant_id)s",
    internal_url_v3     => "http://${::centos_cloud::params::controller}:8776/v3/%(tenant_id)s",
    admin_url_v3        => "http://${::centos_cloud::params::controller}:8776/v3/%(tenant_id)s",
    password            => $password,
  }

  class { '::cinder':
    database_connection   => "mysql+pymysql://cinder:${password}@${::centos_cloud::params::controller}/cinder?charset=utf8",
    default_transport_url => $transport_url
  }

  class { '::cinder::keystone::authtoken':
    auth_uri            => "http://${::centos_cloud::params::controller}:5000",
    auth_url            => "http://${::centos_cloud::params::controller}:35357",
    memcached_servers   => $::centos_cloud::params::memcached_servers,
    password            => $password,
    project_domain_name => 'Default',
    user_domain_name    => 'Default'
  }

  class { '::cinder::api':
    default_volume_type => 'DEFAULT',
    public_endpoint     => "http://${::centos_cloud::params::controller}:8776",
    service_name        => 'httpd'
  }

  include ::apache
  class { '::cinder::wsgi::apache':
    bind_host => '0.0.0.0',
    ssl       => false,
    threads   => $threads,
    workers   => $workers
  }

  class { '::cinder::quota': }
  class { '::cinder::scheduler': }
  class { '::cinder::scheduler::filter': }
  class { '::cinder::volume':
    volume_clear => 'none',
  }
  class { '::cinder::cron::db_purge': }
  class { '::cinder::glance':
    glance_api_servers => "http://${::centos_cloud::params::controller}:9292",
  }

  cinder::backend::iscsi { 'DEFAULT':
    iscsi_ip_address   => '127.0.0.1',
    manage_volume_type => true,
  }

  class { '::cinder::backends':
    enabled_backends => ['DEFAULT'],
  }
}
