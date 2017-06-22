class centos_cloud::server::auth_file (
  $password   = 'keystone',
  $path       = '/root/openrc_admin'
){
  include centos_cloud::params

  class { '::openstack_extras::auth_file':
    auth_url       => "http://${::centos_cloud::params::controller}:5000/v3/",
    password       => $password,
    path           => $path,
    project_domain => 'default',
    user_domain    => 'default'
  } ->
  exec { 'Setup openstackclient bash completion':
    command => "/usr/bin/bash -c 'source ${path}; /usr/bin/openstack complete >> ${path}'",
    unless  => "/usr/bin/grep -q '_openstack()' ${path}"
  }
}
