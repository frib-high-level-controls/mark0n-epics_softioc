define epicssoftioc::ioc(
  $ensure = undef,
  $enable = undef,
  $bootdir = 'iocBoot/ioc${HOST_ARCH}',
  $startscript = 'st.cmd',
  $consolePort = 4051
)
{
  if $ensure and !($ensure in ['running', 'stopped']) {
    fail("ensure parameter must be 'running', 'stopped' or undefined")
  }
  if $enable {
    validate_bool($enable)
  }
  $iocbase = $epicssoftioc::iocbase

  if($bootdir) {
    $absbootdir = "$iocbase/$name/$bootdir"
  } else {
    $absbootdir = "$iocbase/$name"
  }

  user { "$name":
    comment	=> "$name testioc",
    home	=> "/epics/iocs/$name",
    groups	=> 'softioc',
  }

  file { "/etc/iocs/$name":
    ensure	=> directory,
    group	=> 'softioc',
    require	=> Class['::epicssoftioc'],
  }

  file { "/etc/iocs/$name/config":
    ensure	=> present,
    content	=> template('/vagrant/modules/epicssoftioc/templates/etc/iocs/ioc_config'),
    notify	=> Service["softioc-$name"],
  }

  exec { "create init script for softioc $name":
    command	=> "/usr/bin/manage-iocs install $name",
    require	=> [
      Class['epicssoftioc'],
      File["/etc/iocs/$name/config"],
      File["$iocbase"],
    ],
    creates	=> "/etc/init.d/softioc-$name",
  }

  if($ensure == undef) {
    service { "softioc-$name":
      ensure		=> undef,
      enable		=> $enable,
      hasrestart	=> true,
      hasstatus		=> true,
      require		=> [
        Exec["create init script for softioc $name"],
      ],
    }
  } else {
    service { "softioc-$name":
      ensure		=> $ensure,
      enable		=> $enable,
      hasrestart	=> true,
      hasstatus		=> true,
      require		=> [
        Exec["create init script for softioc $name"],
      ],
    }
  }
}