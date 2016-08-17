  This Puppet module installs and configures an EPICS soft IOC. The IOC is run
  in procserv to ease maintenance. The IOC can be started/stopped using an init
  script.
  On systems that use systemd as init system (e.g. Debian Jessie) a systemd
  unit file will be created for each IOC process. On older systems (e.g. Debian
  Wheezy) this module relies on sysv-rc-softioc for creating System V init
  scripts instead.

# Environment Variables
  Some attributes of the Epics_softioc::Ioc class cause environment variables
  to be set. Please refer to the following table for a list:

  | Attribute          | Environment Variable     |
  |--------------------|--------------------------|
  | ca_addr_list       | EPICS_CA_ADDR_LIST       |
  | ca_auto_addr_list  | EPICS_CA_AUTO_ADDR_LIST  |
  | ca_max_array_bytes | EPICS_CA_MAX_ARRAY_BYTES |
  | log_port           | EPICS_IOC_LOG_PORT       |
  | log_server         | EPICS_IOC_LOG_INET       |

  Environment variables that are not on this list can be set using the
  `env_vars` attribute.

# Examples

## Simple

  $iocbase = '/usr/local/lib/iocapps'

  class { 'epics_softioc':
    iocbase => $iocbase,
  }

  epics_softioc::ioc { 'mysoftioc':
    ensure      => running,
    enable      => true,
    bootdir     => 'iocBoot/ioclinux-x86_64',
    require     => File["${iocbase}/mysoftioc"],
  }

## Complex
  In this example we run two IOC processes on the same machine. Thus different
  ProcServ ports need to be used. See the first block for an example of setting
  facility-wide defaults.

  Epics_softioc::Ioc {
    log_port   => 6500,
    log_server => 'logserver.example.com',
  }

  $iocbase = '/usr/local/lib/iocapps'

  class { 'epics_softioc':
    iocbase => $iocbase,
  }

  epics_softioc::ioc { 'vacuum':
    ensure            => running,
    enable            => true,
    bootdir           => 'iocBoot/ioclinux-x86_64',
    consolePort       => 4051,
    ca_addr_list      => '',
    ca_auto_addr_list => true,
    env_vars          => {
      'EPICS_CA_CONN_TMO'     => '1',
      'EPICS_CA_NAME_SERVERS' => 'nameserver.example.com',
    },
    uid               => 900,
    require           => File["${iocbase}/vacuum"],
  }

  epics_softioc::ioc { 'llrf':
    ensure      => running,
    enable      => true,
    bootdir     => 'iocBoot/ioclinux-x86_64',
    consolePort => 4052,
    uid         => 901,
    require     => File["${iocbase}/llrf"],
  }

# Contact
  Author: Martin Konrad <konrad at frib.msu.edu>