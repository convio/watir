$: << File.dirname(__FILE__)
require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/testtask'
require 'rdoc/task'
require 'rubygems/package_task'

require 'watir-rdoc'

$VERBOSE = nil
desc 'Generate Watir API Documentation'
Rake::RDocTask.new('rdoc') do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.options += $WATIR_RDOC_OPTIONS
  rdoc.rdoc_files.include('lib/watir/ie.rb')
  $WATIR_EXTRA_RDOC_FILES.each do |file|
    rdoc.rdoc_files.include(file)
  end
  rdoc.rdoc_files.include('lib/watir/contrib/*.rb')
  rdoc.rdoc_files.include('lib/watir/dialogs/*.rb')
  rdoc.rdoc_files.include('lib/watir/*.rb')
  rdoc.rdoc_files.exclude('lib/watir/camel_case.rb')
end

Rake::TestTask.new do |t|
  t.test_files = FileList['unittests/core_tests.rb']
  t.verbose = true
end

CLEAN << 'pkg' << 'rdoc'


desc 'Attach to an active IE window'
task :attach do
  sh "irb.bat -r attach.rb"
end

task :default => :package

if defined? Gem::PackageTask

  gemspec = eval(File.read('watir.gemspec'))

  Gem::PackageTask.new(gemspec) do |p|
    p.gem_spec = gemspec
    p.need_tar = false
    p.need_zip = false
  end

else
  puts 'Warning: without Rubygems packaging tasks are not available'
end

