raise 'requires JRuby -- "jruby $(which rake) test"' unless RUBY_PLATFORM =~ /java/

STDOUT.puts 'Detected JRuby v%s' % JRUBY_VERSION

require 'init'

# load vendor helpers
require 'find'
vendor = File.join(EJBDispatcher::HOME,'vendor','test')
if File.exists?(vendor)
  Find.find(vendor) do |file|
    require file if file[/_helper.rb$/]
  end
end

def java_time(*args)
  Time.mktime(*args).to_i*1000
end

EJBDispatcher.set_logger
EJBDispatcher.logger.level = Logger::FATAL