# This type configures an EPICS soft IOC. It creates configuration files,
# automatically populates them with the correct values and installs the
# registers the service.
#
define epics_softioc::ioc(
  $ensure = undef,
  $enable = undef,
  $bootdir = 'iocBoot/ioc${HOST_ARCH}',
  $startscript = 'st.cmd',
  $consolePort = 4051
)
{
  if $ensure and !($ensure in ['running', 'stopped']) {
    fail('ensure parameter must be "running", "stopped" or <undefined>')
  }
  if $enable {
    validate_bool($enable)
  }
  $iocbase = $epics_softioc::iocbase

  if($bootdir) {
    $absbootdir = "${iocbase}/${name}/${bootdir}"
  } else {
    $absbootdir = "${iocbase}/${name}"
  }

  user { $name:
    comment => "${name} testioc",
    home    => "/epics/iocs/${name}",
    groups  => 'softioc',
  }

  file { "/etc/iocs/${name}":
    ensure  => directory,
    group   => 'softioc',
    require => Class['::epics_softioc'],
  }

  file { "/etc/iocs/${name}/config":
    ensure  => present,
    content => template('epics_softioc/etc/iocs/ioc_config'),
    notify  => Service["softioc-${name}"],
  }

  exec { "create init script for softioc ${name}":
    command => "/usr/bin/manage-iocs install ${name}",
    require => [
      Class['epics_softioc'],
      File["/etc/iocs/${name}/config"],
      File[$iocbase],
    ],
    creates => "/etc/init.d/softioc-${name}",
  }

  service { "softioc-${name}":
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      Exec["create init script for softioc ${name}"],
      User[$name],
    ],
  }
}