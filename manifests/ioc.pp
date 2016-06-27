# This type configures an EPICS soft IOC. It creates configuration files,
# automatically populates them with the correct values and installs the
# registers the service.
#
define epics_softioc::ioc(
  $ensure      = undef,
  $enable      = undef,
  $bootdir     = "iocBoot/ioc\${HOST_ARCH}",
  $startscript = 'st.cmd',
  $consolePort = 4051,
  $coresize    = 10000000,
  $cfg_append  = [],
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

  $user = "softioc-${name}"

  user { $user:
    comment => "${name} IOC",
    home    => "/epics/iocs/${name}",
    groups  => 'softioc',
  }

  if $::initsystem == 'systemd' {
    $procServLogfile = "/var/log/softioc-${name}"
    $absstartscript = "${absbootdir}/${startscript}"

    file { "/etc/systemd/system/softioc-${name}.service":
      content => template("${module_name}/etc/systemd/system/ioc.service"),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    exec { 'reload systemd configuration':
      command     => '/bin/systemctl daemon-reload',
      subscribe   => File["/etc/systemd/system/softioc-${name}.service"],
      refreshonly => true,
      notify      => Service["softioc-${name}"],
    }
  } else {
    file { "/etc/iocs/${name}":
      ensure  => directory,
      group   => 'softioc',
      require => Class['::epics_softioc'],
    }

    file { "/etc/iocs/${name}/config":
      ensure  => present,
      content => template("${module_name}/etc/iocs/ioc_config"),
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
      before  => Service["softioc-${name}"],
    }
  }

  file { "/var/lib/softioc-${name}":
    ensure => directory,
    owner  => 'root',
    group  => 'softioc',
    mode   => '0775',
  }

  service { "softioc-${name}":
    ensure     => $ensure,
    enable     => $enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [
      User[$user],
      File["/var/lib/softioc-${name}"],
      Package['procserv'],
    ],
  }
}