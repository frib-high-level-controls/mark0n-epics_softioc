# This type configures an EPICS soft IOC. It creates configuration files,
# automatically populates them with the correct values and installs the
# registers the service.
#
define epics_softioc::ioc(
  Optional[Enum['running', 'stopped']]   $ensure                      = undef,
  Optional[Boolean]                      $enable                      = undef,
  Boolean                                $manage_autosave_dir         = false,
  Boolean                                $auto_restart_ioc            = true,
  String                                 $autosave_base_dir           = '/var/lib',
  String                                 $bootdir                     = "iocBoot/ioc\${HOST_ARCH}",
  Optional[String]                       $ca_addr_list                = undef,
  Optional[Boolean]                      $ca_auto_addr_list           = undef,
  Optional[Integer]                      $ca_max_array_bytes          = undef,
  String                                 $startscript                 = 'st.cmd',
  Integer[1, 65535]                      $consolePort                 = 4051,
  Integer                                $coresize                    = 10000000,
  Array[String]                          $cfg_append                  = [],
  Hash[String, String, default, default] $env_vars                    = {},
  Integer[1, 65535]                      $log_port                    = 7004,
  Optional[String]                       $log_server                  = undef,
  Optional[String]                       $ca_sec_file                 = undef,
  String                                 $procServ_logfile            = "/var/log/softioc-${name}/procServ.log",
  Boolean                                $logrotate_compress          = true,
  Integer                                $logrotate_rotate            = 30,
  String                                 $logrotate_size              = '10M',
  Boolean                                $run_make                    = true,
  Optional[Integer]                      $uid                         = undef,
  String                                 $abstopdir                   = "${epics_softioc::iocbase}/${name}",
  String                                 $username                    = "softioc-${name}",
  Boolean                                $manage_user                 = true,
  Array[String]                          $systemd_after               = [ 'network.target' ],
  Array[String]                          $systemd_requires            = [ 'network.target' ],
  Array[String]                          $systemd_requires_mounts_for = [],
)
{
  $iocbase = $epics_softioc::iocbase

  if($bootdir) {
    $absbootdir = "${abstopdir}/${bootdir}"
  } else {
    $absbootdir = $abstopdir
  }

  if $ca_addr_list {
    $env_vars2 = merge($env_vars, {'EPICS_CA_ADDR_LIST' => $ca_addr_list})
  } else {
    $env_vars2 = $env_vars
  }

  if $ca_auto_addr_list {
    $auto_addr_list_str = $ca_auto_addr_list ? {
      true  => 'YES',
      false => 'NO',
    }
    $env_vars3 = merge($env_vars2, {'EPICS_CA_AUTO_ADDR_LIST' => $auto_addr_list_str})
  } else {
    $env_vars3 = $env_vars2
  }

  if $ca_max_array_bytes {
    $env_vars4 = merge($env_vars3, {'EPICS_CA_MAX_ARRAY_BYTES' => $ca_max_array_bytes})
  } else {
    $env_vars4 = $env_vars3
  }

  $env_vars5 = merge($env_vars4, {'EPICS_IOC_LOG_PORT' => $log_port})

  if $log_server {
    $env_vars6 = merge($env_vars5, {'EPICS_IOC_LOG_INET' => $log_server})
  } else {
    $env_vars6 = $env_vars5
  }

  if $ca_sec_file {
    $env_vars7 = merge($env_vars6, {'EPICS_CA_SEC_FILE' => $ca_sec_file})
  } else {
    $env_vars7 = $env_vars6
  }

  if $manage_autosave_dir {
    $real_env_vars = merge($env_vars7, {'AUTOSAVE_DIR' => "${autosave_base_dir}/softioc-${name}"})
  } else {
    $real_env_vars = $env_vars7
  }

  if $run_make {
    exec { "build IOC ${name}":
      command   => '/usr/bin/make distclean all',
      cwd       => $abstopdir,
      umask     => '002',
      unless    => '/usr/bin/make CHECK_RELEASE=NO CHECK_RELEASE_NO= --question',
      require   => Class['epics_softioc::software'],
      subscribe => Package['epics-dev'],
    }
  }

  if $manage_user {
    user { $username:
      comment => "${name} IOC",
      home    => "/epics/iocs/${name}",
      groups  => 'softioc',
      uid     => $uid,
      before  => Service["softioc-${name}"],
    }
  }

  if($manage_autosave_dir) {
    file { "${autosave_base_dir}/softioc-${name}":
      ensure => directory,
      owner  => $username,
      group  => 'softioc',
      mode   => '0775',
      before => Service["softioc-${name}"],
    }
  }

  if $::initsystem == 'systemd' {
    $absstartscript = "${absbootdir}/${startscript}"

    systemd::unit_file { "softioc-${name}.service":
      content => template("${module_name}/etc/systemd/system/ioc.service"),
      notify  => Service["softioc-${name}"],
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

  file { "/var/log/softioc-${name}":
    ensure => directory,
    owner  => $username,
    group  => 'softioc',
    mode   => '2755',
  }

  logrotate::rule { "softioc-${name}":
    path         => $procServ_logfile,
    rotate_every => 'day',
    rotate       => $logrotate_rotate,
    size         => $logrotate_size,
    missingok    => true,
    ifempty      => false,
    postrotate   => "/bin/systemctl kill --signal=HUP --kill-who=main softioc-${name}.service",
    compress     => $logrotate_compress,
  }

  if $::initsystem == 'systemd' {
    service { "softioc-${name}":
      ensure     => $ensure,
      enable     => $enable,
      hasrestart => true,
      hasstatus  => true,
      provider   => 'systemd',
      require    => [
        Class['epics_softioc::software'],
        Package['procserv'],
        Class['systemd::systemctl::daemon_reload'],
        File["/var/log/softioc-${name}"],
      ],
    }
  } else {
    service { "softioc-${name}":
      ensure     => $ensure,
      enable     => $enable,
      hasrestart => true,
      hasstatus  => true,
      require    => [
        Class['epics_softioc::software'],
        Package['procserv'],
        Class['systemd::systemctl::daemon_reload'],
        File["/var/log/softioc-${name}"],
      ],
    }
  }

  if $run_make and $auto_restart_ioc {
    Exec["build IOC ${name}"] ~> Service["softioc-${name}"]
  }
}
