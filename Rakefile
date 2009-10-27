require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the EJB dispatcher RMI client + DRb server.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = [ 'test/**/*_test.rb' ]
  t.pattern << 'vendor/test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'EJB dispatcher'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.options << '-U' << '-x deprecated'
  rdoc.options << '--line-numbers' << '--inline-source'
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "ejb-dispatcher"
    gemspec.summary = "EJB-dispatcher"
    gemspec.description = "Describe your gem"
    gemspec.email = "mikael.lammentausta+github+@gmail.com"
    gemspec.homepage = "http://github.com/lamikae/ejb-dispatcher"
    gemspec.description = "README"
    gemspec.authors = ["Mikael Lammentausta"]
    gemspec.executables = "ejb-dispatcher.rb"
    gemspec.files.exclude "wiki"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end


desc 'Build the RubyGem'
task :gem => :gemspec do
  system("gem build ejb-dispatcher.gemspec")
end