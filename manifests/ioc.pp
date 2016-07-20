# This type configures an EPICS soft IOC. It creates configuration files,
# automatically populates them with the correct values and installs the
# registers the service.
#
define epics_softioc::ioc(
  $ensure           = undef,
  $enable           = undef,
  $bootdir          = "iocBoot/ioc\${HOST_ARCH}",
  $startscript      = 'st.cmd',
  $consolePort      = 4051,
  $coresize         = 10000000,
  $cfg_append       = [],
  $procServ_logfile = "/var/log/softioc/${name}-procServ.log",
  $logrotate_rotate = 30,
  $logrotate_size   = '10M',
)
{
  if $ensure and !($ensure in ['running', 'stopped']) {
    fail('ensure parameter must be "running", "stopped" or <undefined>')
  }
  if $enable {
    validate_bool($enable)
  }
  $iocbase = $epics_softioc::iocbase

  $abstopdir = "${iocbase}/${name}"

  if($bootdir) {
    $absbootdir = "${abstopdir}/${bootdir}"
  } else {
    $absbootdir = $abstopdir
  }

  $user = "softioc-${name}"

  exec { "build IOC ${name}":
    command => '/usr/bin/make',
    cwd     => $abstopdir,
    creates => "${abstopdir}/bin",
    require => Class['epics_softioc::software'],
  }

  user { $user:
    comment => "${name} IOC",
    home    => "/epics/iocs/${name}",
    groups  => 'softioc',
  }

  if $::initsystem == 'systemd' {
    $absstartscript = "${absbootdir}/${startscript}"

    file { "/etc/systemd/system/softioc-${name}.service":
      content => template("${module_name}/etc/systemd/system/ioc.service"),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      notify  => Exec['reload systemd configuration'],
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

  logrotate::rule { "softioc-${name}":
    path         => $procServ_logfile,
    rotate_every => 'day',
    rotate       => $logrotate_rotate,
    size         => $logrotate_size,
    missingok    => true,
    ifempty      => false,
    postrotate   => "/bin/systemctl kill --signal=HUP --kill-who=main softioc-${name}.service",
  }

  if $::initsystem == 'systemd' {
    service { "softioc-${name}":
      ensure     => $ensure,
      enable     => $enable,
      hasrestart => true,
      hasstatus  => true,
      provider   => 'systemd',
      require    => [
        User[$user],
        Package['procserv'],
        Exec['reload systemd configuration'],
      ],
      subscribe  => File["/var/lib/softioc-${name}"],
    }
  } else {
    service { "softioc-${name}":
      ensure     => $ensure,
      enable     => $enable,
      hasrestart => true,
      hasstatus  => true,
      require    => [
        User[$user],
        Package['procserv'],
        Exec['reload systemd configuration'],
      ],
      subscribe  => File["/var/lib/softioc-${name}"],
    }
  }
}