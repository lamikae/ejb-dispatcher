raise 'requires JRuby -- "jruby $(which rake) test"' unless RUBY_PLATFORM =~ /java/

STDOUT.puts 'Detected JRuby v%s' % JRUBY_VERSION

this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))

require this_dir + '/../lib/libejb-dispatcher'

# FIXME: load vendor helpers !!!
#require 'find'

# there is no point ...

# vendor = File.join(EJBDispatcher::HUB,'test')
# unless File.exists?(vendor)
#   EJBDispatcher.warn 'mh'
# else
  #Find.find(vendor) do |file|
  #  require file if file[/_helper.rb$/]
  #end
# end

def java_time(*args)
  Time.mktime(*args).to_i*1000
end


def flunk_without_ejb_host
  if EJBDispatcher::HUB.nil?
    flunk 'This test cannot be run without a properly set up EJB hub.'
  end
end

class Test::Unit::TestCase
  def setup
    #ENV['DISPATCHER_CONFIG']=nil
    EJBDispatcher.set_config
    EJBDispatcher.set_logger
    EJBDispatcher.logger.level = Logger::FATAL
  end
end
