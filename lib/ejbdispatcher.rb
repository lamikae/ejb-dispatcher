# Handles a single DRb server thread.
module EJBDispatcher
  VERSION = '1.0.0_RC'

  # Meta magic.
  module ClassMethods
    
    # Defines class methods from vendor models for this instance of the EJB.
    #
    # All instances of this particular EJB will then share this method.
    def define_attr_method(name, value=nil)
      #logger.debug 'Defining %s' % name
      (class << self; self; end).class_eval "def #{name}; #{value.to_s.inspect}; end"
    end
    
    # Defines @attribute reader for this instance.
    def define_attr_reader(name)
      (class << self; self; end).class_eval "attr_reader :#{name}"
    end
    
  end

  def self.included(base)
    base.extend(EJBDispatcher::ClassMethods)
  end

  extend ClassMethods
  
  class << self

    public

    # Reads config file
    #
    #   sets attr_reader :config
    #
    # tunes the logger level according to configuration
    def set_config
      logger.debug 'Locating configuration file'
      if ENV['DISPATCHER_CONFIG']
        config_file = ENV['DISPATCHER_CONFIG']
      else
        this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
        this_dir = File.dirname(File.expand_path(this_file))
        config_file = File.join(this_dir,'..','config','dispatcher.yml')
      end
      logger.debug config_file
      unless File.exists?(config_file)
        logger.warn 'Configuration file "%s" does not exist' % config_file
      else
        @config = YAML.load_file(config_file)
        define_attr_reader :config
        if logger and
          config['logger'] and
          config['logger']['level'] then
          logger.level = Logger.const_get(config['logger']['level'])
        end
        # TODO: read vendor config
        logger.debug 'Configuration: %s' % config.inspect
      end
    end

    # instance logger
    #   sets attr_reader :logger
    def set_logger
      @logger = Logger.new(STDOUT)
      #@logger = Logger.new('dispatcher.log')
      define_attr_reader :logger
    end

    # Collects the threads for EJB-DRbServers defined in the configuration file.
    #
    def collect_dispatchers
      logger.debug 'Collecting dispatchers'
      dispatchers = []
      self.ejbs.each do |ejb|
        dispatchers << Instance.new(ejb[0])
      end

      logger.debug dispatchers.inspect
      return dispatchers
    end

    # List of configured ejbs.
    def ejbs
      config = @config.dup
      config.delete('logger')
      return config
    end

  end
end
