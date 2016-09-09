# This type configures an EPICS soft IOC. It creates configuration files,
# automatically populates them with the correct values and installs the
# registers the service.
#
define epics_softioc::ioc(
  $ensure              = undef,
  $enable              = undef,
  $manage_autosave_dir = false,
  $auto_restart_ioc    = true,
  $autosave_base_dir   = '/var/lib',
  $bootdir             = "iocBoot/ioc\${HOST_ARCH}",
  $ca_addr_list        = undef,
  $ca_auto_addr_list   = undef,
  $ca_max_array_bytes  = undef,
  $startscript         = 'st.cmd',
  $consolePort         = 4051,
  $coresize            = 10000000,
  $cfg_append          = [],
  $env_vars            = {},
  $log_port            = undef,
  $log_server          = undef,
  $procServ_logfile    = "/var/log/softioc/${name}-procServ.log",
  $logrotate_rotate    = 30,
  $logrotate_size      = '10M',
  $uid                 = undef,
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

  validate_bool($auto_restart_ioc)

  validate_bool($manage_autosave_dir)
  if($manage_autosave_dir) {
    validate_absolute_path($autosave_base_dir)
  }

  if($bootdir) {
    $absbootdir = "${abstopdir}/${bootdir}"
  } else {
    $absbootdir = $abstopdir
  }

  validate_hash($env_vars)

  if $ca_addr_list {
    validate_string($ca_addr_list)
    $env_vars2 = merge($env_vars, {'EPICS_CA_ADDR_LIST' => $ca_addr_list})
  } else {
    $env_vars2 = $env_vars
  }

  if $ca_auto_addr_list {
    validate_bool($ca_auto_addr_list)
    $auto_addr_list_str = $ca_auto_addr_list ? {
      true  => 'YES',
      false => 'NO',
    }
    $env_vars3 = merge($env_vars2, {'EPICS_CA_AUTO_ADDR_LIST' => $auto_addr_list_str})
  } else {
    $env_vars3 = $env_vars2
  }

  if $ca_max_array_bytes {
    validate_integer($ca_max_array_bytes, undef, 16384)
    $env_vars4 = merge($env_vars3, {'EPICS_CA_MAX_ARRAY_BYTES' => $ca_max_array_bytes})
  } else {
    $env_vars4 = $env_vars3
  }

  if $log_port {
    validate_integer($log_port, 65535, 1)
    $env_vars5 = merge($env_vars4, {'EPICS_IOC_LOG_PORT' => $log_port})
  } else {
    $env_vars5 = $env_vars4
  }

  if $log_server {
    validate_string($log_server)
    $env_vars6 = merge($env_vars5, {'EPICS_IOC_LOG_INET' => $log_server})
  } else {
    $env_vars6 = $env_vars5
  }

  if $manage_autosave_dir {
    $real_env_vars = merge($env_vars6, {'AUTOSAVE_DIR' => "${autosave_base_dir}/softioc-${name}"})
  } else {
    $real_env_vars = $env_vars6
  }

  if $uid {
    validate_integer($uid)
  }

  $user = "softioc-${name}"

  exec { "build IOC ${name}":
    command => '/usr/bin/make',
    cwd     => $abstopdir,
    unless  => '/usr/bin/make --dry-run',
    require => Class['epics_softioc::software'],
  }

  user { $user:
    comment => "${name} IOC",
    home    => "/epics/iocs/${name}",
    groups  => 'softioc',
    uid     => $uid,
  }

  if($manage_autosave_dir) {
    file { "${autosave_base_dir}/softioc-${name}":
      ensure => directory,
      owner  => $user,
      group  => 'softioc',
      mode   => '0775',
      before => Service["softioc-${name}"],
    }
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
    }
  }

  if $auto_restart_ioc {
    Exec["build IOC ${name}"] ~> Service["softioc-${name}"]
  }
}