class centos_cloud::compute::neutron (
  $password                    = 'neutron',
  $physical_interface_mappings = ['physnet0:eth0']
) {

  $transport_url = os_transport_url({
    'host'      => $::centos_cloud::params::controller,
    'password'  => $password,
    'port'      => '5672',
    'transport' => 'rabbit',
    'username'  => 'neutron'
  })

  class { '::neutron':
    allow_overlapping_ips   => false,
    bind_host               => '0.0.0.0',
    core_plugin             => 'ml2',
    default_transport_url   => $transport_url,
    dhcp_agent_notification => true,
  }

  class { '::neutron::plugins::ml2':
    flat_networks        => ['physnet0'],
    mechanism_drivers    => ['linuxbridge'],
    tenant_network_types => [],
    type_drivers         => ['flat']
  }

  class { '::neutron::agents::ml2::linuxbridge':
    firewall_driver             => 'neutron.agent.firewall.NoopFirewallDriver',
    physical_interface_mappings => $physical_interface_mappings
  }

  class { '::neutron::agents::dhcp':
    interface_driver => 'neutron.agent.linux.interface.BridgeInterfaceDriver'
  }
}
