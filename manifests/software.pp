# This class installs software which are needed in order to build and run a
# soft IOC.
#
class epics_softioc::software() {
  package { 'build-essential':
    ensure => hiera('epics_softioc::software::ensure_build-essential', 'latest'),
  }

  package { 'epics-dev':
    ensure => hiera('epics_softioc::software::ensure_epics-dev', 'latest'),
  }

  include 'telnet'

  package { 'procserv':
    ensure => hiera('epics_softioc::software::ensure_procserv', 'latest'),
  }
}