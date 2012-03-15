require 'rubygems'
require 'rake/clean'
require 'fileutils'

projects = ['watir', 'commonwatir']

def launch_subrake(cmd)
  command = "#{Gem.ruby} -S rake #{cmd}"
  sh (command) do |ok, status|
    unless ok
      puts "Command filed with status (#{status.exitstatus}): [#{command}]"
      exit 1
    end
  end
end

task :default => :gems

task :gemdir do
  mkdir_p "gems" if !File.exist?("gems")
end

desc "Generate all the Watir gems"
task :gems => :gemdir do
  projects.each do |project|
    tmp_files = %w{CHANGES VERSION  README.rdoc LICENSE}
    FileUtils.cp tmp_files, project
    Dir.chdir(project) do
      launch_subrake "gem"
      FileUtils.rm tmp_files
    end
  end
  gems = Dir['*/pkg/*.gem']
  gems.each {|gem| FileUtils.install gem, 'gems'}
end

desc "Clean all the projects"
task :clean_subprojects do
  projects.each do |project|
    Dir.chdir(project) do
      launch_subrake "clean"
    end
  end
end

desc "Clean the build environment and projects"
task :clean => [:clean_subprojects] do
  FileUtils.rm_r Dir.glob("gems/*") << "test/reports", :force => true
end

desc "Run tests for Watir"
task :test => [:test_watir]

desc 'Run tests for Watir'
task :test_watir do
  Dir.chdir("watir") do
    launch_subrake "test"
  end
end

task :deploy => [:clean, :gems] do
  Dir.chdir("gems") do
    sh "gem install --local --no-ri * --ignore-dependencies"
  end
end


#
# ------------------------------ watirspec -----------------------------------
#

if File.exist?(path = "spec/watirspec/watirspec.rake")
  load path
end

namespace :watirspec do
  desc 'Initialize and fetch the watirspec submodule'
  task :init do
    sh "git submodule init"
    sh "git submodule update"
  end
end
