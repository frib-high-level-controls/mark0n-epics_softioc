class epicssoftioc($iocbase = '/usr/local/lib/iocapps') {
  package { 'epics-dev':
    ensure	=> installed,
  }

  package { 'telnet':
    ensure	=> installed,
  }

  package { 'sysv-rc-softioc':
    ensure	=> installed,
  }

  group { 'softioc':
    ensure	=> present,
  }

  file { '/etc/default/epics-softioc':
    content	=> template('epicssoftioc/etc/default/epics-softioc'),
    owner	=> root,
    group	=> root,
    mode	=> '0644',
    require	=> Package['sysv-rc-softioc'],
  }

  file { '/etc/iocs':
    ensure	=> directory,
    owner	=> 'root',
    group	=> 'softioc',
  }

  file { "$iocbase":
    ensure	=> directory,
    owner	=> 'root',
    group	=> 'softioc',
    mode	=> '2755',
  }
}