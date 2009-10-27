require 'test/unit'
require 'yaml'
this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))
require this_dir+'/test_helper' # no helper - no init!

class DispatcherTest < Test::Unit::TestCase
  def setup
    @config = {
    "ejb00"=>{"port"=>9875, "class"=>"EJB00", "hostname"=>"localhost"},
    "ejb01"=>{"port"=>9874, "class"=>"EJB01", "hostname"=>"localhost"},
    "ejb21"=>{"port"=>9876, "class"=>"EJB21", "hostname"=>"localhost"},
    "logger"=>{"level"=>"FATAL"}
    }
    # write tmp config file
    this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    this_dir = File.dirname(File.expand_path(this_file))
    @configfile = File.join(this_dir,'.test_config.yml')
    File.open(@configfile,'w') do |out|
      YAML.dump(@config,out)
    end

    # set the env variable before requiring init!
    ENV['DISPATCHER_CONFIG']=@configfile
    EJBDispatcher.set_config
    @init = File.join(this_dir,'..','init')
  end

  def test_config
    assert_equal @config, EJBDispatcher.config
  end

  def test_logger
    EJBDispatcher.set_config
    logger = EJBDispatcher.logger
    level = Logger.const_get(@config['logger']['level'])
    assert_equal level, logger.level, 'Logger level is not read from configuration'

    # alter level
    level = Logger::FATAL
    logger.level = level
    assert_equal level, logger.level
    loggerB = EJBDispatcher.logger
    assert_equal level, loggerB.level
    assert_equal logger, loggerB, 'Logger level is not consistant'
  end

  def test_ejbs
    EJBDispatcher.set_config
    %w( ejb00 ejb01 ejb21 ).each do |ejb|
      assert EJBDispatcher.ejbs.keys.include?(ejb)
    end
  end

  def test_instances
    EJBDispatcher.set_config
    instances = EJBDispatcher.collect_dispatchers
    assert_equal 3,instances.size
  end

  def teardown
    File.delete(@configfile)
  end

end