# This class takes care of all global tasks which are needed in order to run a
# soft IOC. It installs the needed packages and prepares machine-global
# directories and configuration files.
#
class epics_softioc($iocbase = '/usr/local/lib/iocapps') {
  package { 'epics-dev':
    ensure => installed,
  }

  package { 'telnet':
    ensure => installed,
  }

  package { 'procserv':
    ensure => installed,
  }

  group { 'softioc':
    ensure => present,
  }

  if $::initsystem != 'systemd' {
    package { 'sysv-rc-softioc':
      ensure => installed,
    }

    file { '/etc/default/epics-softioc':
      content => template("${module_name}/etc/default/epics-softioc"),
      owner   => root,
      group   => root,
      mode    => '0644',
      require => Package['sysv-rc-softioc'],
    }
  }

  file { '/etc/iocs':
    ensure => directory,
    owner  => 'root',
    group  => 'softioc',
  }

  file { $iocbase:
    ensure => directory,
    owner  => 'root',
    group  => 'softioc',
    mode   => '2755',
  }
}