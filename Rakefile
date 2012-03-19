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

desc "deploy the gem to the gem server; must be run on on gem server"
task :deploy => [:clean, :gems] do
  gemserver=ENV['GEM_SERVER']
  ssh_options='-o User=root -o IdentityFile=~/.ssh/0-default.private -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null'
  temp_dir=`ssh #{ssh_options} #{gemserver} 'mktemp -d'`.strip
  system("scp #{ssh_options} gems/*.gem '#{gemserver}:#{temp_dir}'")
  system("ssh #{ssh_options} #{gemserver} 'gem install --local --no-ri #{temp_dir}/*.gem --ignore-dependencies'")
  system("ssh #{ssh_options} #{gemserver} 'rm -rf #{temp_dir}'")
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
