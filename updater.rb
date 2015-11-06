#!/usr/bin/env ruby

# updater version 0.1.0

File.rename("comm_calc.rb", "previous_version")
File.rename("latest","comm_calc.rb")
puts "update complete"
exec 'ruby comm_calc.rb'
exit()
