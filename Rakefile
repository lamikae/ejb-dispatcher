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

