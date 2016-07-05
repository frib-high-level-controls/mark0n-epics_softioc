# This class installs software which are needed in order to build and run a
# soft IOC.
#
class epics_softioc::software() {
  package { 'build-essential':
    ensure => installed,
  }

  package { 'epics-dev':
    ensure => installed,
  }

  package { 'telnet':
    ensure => installed,
  }

  package { 'procserv':
    ensure => installed,
  }
}