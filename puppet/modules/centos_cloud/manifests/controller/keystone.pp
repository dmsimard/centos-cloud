class centos_cloud::controller::keystone (
  $password            = 'keystone',
  $admin_token         = 'admintoken',
  $admin_password      = 'admin',
  $admin_workers       = '16',
  $public_workers      = '16',
  $workers             = '16',
  $threads             = '1'
) {

  include centos_cloud::params

  class { '::keystone::client': }
  class { '::keystone::cron::token_flush': }

  class { '::keystone::db::mysql':
    allowed_hosts => [
      $::centos_cloud::params::controller,
      $::centos_cloud::params::allowed_hosts
    ],
    password => $password,
  }

  class { '::keystone':
    admin_bind_host         => '0.0.0.0',
    admin_password          => $admin_password,
    admin_token             => $admin_token,
    admin_workers           => $admin_workers,
    database_connection     => "mysql+pymysql://keystone:${password}@${::centos_cloud::params::controller}/keystone",
    enable_credential_setup => true,
    enable_fernet_setup     => true,
    enabled                 => true,
    public_bind_host        => '0.0.0.0',
    public_workers          => $public_workers,
    service_name            => 'httpd',
    token_expiration        => 600,
    token_provider          => 'fernet'
  }

  include ::apache
  class { '::keystone::wsgi::apache':
    admin_bind_host => '0.0.0.0',
    bind_host       => '0.0.0.0',
    servername      => $::centos_cloud::params::controller,
    ssl             => false,
    threads         => $threads,
    workers         => $workers
  }

  class { '::keystone::roles::admin':
    email    => 'ci@centos.org',
    password => $admin_password
  }

  class { '::keystone::endpoint':
    admin_url    => "http://${::centos_cloud::params::controller}:35357",
    internal_url => "http://${::centos_cloud::params::controller}:5000",
    public_url   => "http://${::centos_cloud::params::controller}:5000"
  }

  include ::keystone::disable_admin_token_auth

  keystone_role { '_member_':
    ensure => present
  }
}
