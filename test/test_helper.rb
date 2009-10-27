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


def flunk_without_ejb_host
  if EJBDispatcher.ejbs['dummy']
    flunk 'This test cannot be run without a proper EJB host.'
  end
end

class Test::Unit::TestCase
  def setup
    ENV['DISPATCHER_CONFIG']=nil
    EJBDispatcher.set_config
    EJBDispatcher.set_logger
    EJBDispatcher.logger.level = Logger::FATAL
  end
end