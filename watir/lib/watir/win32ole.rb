# load the correct version of win32ole

# Use our modified win32ole library
puts 'HERHEHREHRHERHERHER'

if RUBY_VERSION =~ /^1\.8/
  $LOAD_PATH.unshift  File.expand_path(File.join(File.dirname(__FILE__), '..', 'watir', 'win32ole', '1.8.7'))
elsif RUBY_VERSION =~ /^1\.9/
  $LOAD_PATH.unshift  File.expand_path(File.join(File.dirname(__FILE__), '..', 'watir', 'win32ole', '1.9.3'))
  puts 'here'
  puts File.expand_path(File.join(File.dirname(__FILE__), '..', 'watir', 'win32ole', '1.9.3'))
else
  # loading win32ole from stdlib
end

puts RUBY_VERSION
puts File.expand_path(File.join(File.dirname(__FILE__), '..', 'watir', 'win32ole', '1.9.3'))
puts require 'win32ole'

WIN32OLE.codepage = WIN32OLE::CP_UTF8
