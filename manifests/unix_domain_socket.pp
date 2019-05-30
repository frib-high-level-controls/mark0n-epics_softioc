# This class contains resources which are required when procServ is used with
# Unix domain sockets
#
class epics_softioc::unix_domain_socket() {
  package { 'netcat-openbsd':
    ensure => lookup('epics_softioc::software::ensure_netcat-openbsd', String, 'first', 'latest'),
  }

  file { '/run/softioc':
    ensure => directory,
    owner  => 'root',
    group  => 'softioc',
    mode   => '0775',
  }
}