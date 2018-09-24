require 'facter'

init_exe = File.readlink('/proc/1/exe')
init_system = File.basename(init_exe)

Facter.add(:initsystem) do
  setcode { init_system }
end
