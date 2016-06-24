require 'facter'

initExe = File.readlink('/proc/1/exe')
initSystem = File.basename(initExe)

Facter.add(:initsystem) {
  setcode { initSystem }
}