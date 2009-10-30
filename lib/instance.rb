module EJBDispatcher
  class Instance

    attr_reader :ejb, :config, :uri

    # Creates and starts the instance.
    # Defaults to Ejbobject, which is of little use.
    def initialize(ejb=nil)
      @ejb = ejb
      @config = {}
      @uri = nil
      set_instance
    end

    # Is the DRbServer alive?
    def alive?
      begin
        srv = DRb.fetch_server(@uri)
        return srv.nil? ? false : srv.alive?
      rescue
        logger.error $!.message
        return false
      end
    end
    alias :is_alive? :alive?

    # Is the front object connected to the DRb?
    # Is the EJB stub ok?
    def connected?
      begin
        srv = DRb.fetch_server(@uri)
        return false if srv.nil?
        return !srv.front.nil?
      rescue
        logger.debug $!.message
        return false
      end
    end

    # The DRb Thread
    def thread
      DRb.thread
    end

    # Sets which EJB instance to start.
    # Sets the @config variable.
    def set_instance
      unless EJBDispatcher.config
        raise 'Configuration error'
      end

      # attr_reader ejb is defined in parse_args
      if defined? @ejb and !@ejb.nil?
        # select the instance from YAML configuration
        @config = EJBDispatcher.config[@ejb]
      else
        # default: EjbObject@localhost:9876
        @ejb = 'default'
        @config = {
          'hostname' => 'localhost',
          'port'     => '9876',
          'class'    => 'EjbObject'
        }
      end
      if config.nil? or config=={} or (config != @config)
        raise ArgumentError, 'Error while setting parameters for "%s"' % @ejb
      end
      # formulate uri
      @hostname = config['hostname']
      @port     = config['port']
      @uri = "druby://#{@hostname}:#{@port}"
      logger.debug 'Instance: %s (%s), URI: %s' % [@ejb,@config['class'],@uri]
    end

    # Which EJB class to share. Is the Class object.
    #
    # Default is EjbObject.
    def klass
      # work around Ruby feature that submodules cannot be converted from "A::B::C" string.
      names = config['class'].split('::')
      _klass = nil
      names.each do |name|
        if _klass.nil?
          _klass = Kernel.const_get(name)
        else
          _klass = _klass.const_get(name)
        end
      end

      config['class'] ?
        _klass :
        EjbObject
    end

    def stop
      logger.debug 'Stopping instance %s (%s)' % [@config['class'], @uri]
      srv = DRb.fetch_server(@uri)
      unless srv
        logger.error 'DRb server not found'
        return false
      end
      srv.stop_service
      return !srv.alive?
    end

    # TODO: document
    def revoke # :nodoc:
      logger.debug 'Revoking instance %s (%s)' % [@config['class'], @uri]
      # locate the DRbServer
      srv = DRb.fetch_server(@uri)

      # copy the home object
      logger.debug 'Front: %s' % srv.front.inspect
      return false unless srv.front
      home = srv.front.__ejbhome.dup

      # stop this DRb server
      #srv.stop_service
      stop()
      # what happens to the thread? is it garbage collected?

      logger.debug 'Revoking EJB from old home: %s' % home.inspect
      # create a new Instance with the home object
      DRb.start_service(@uri, klass.invoke(home))
      # note: the old thread maybe should be terminated?!! does dup affect this?
      return DRb.thread
    end

    # Returns the thread of an instance
    def start_thread
      logger.info 'Instance: %s (%s)' % [ejb,config['class']]
      logger.info 'URI: %s' % @uri
      #logger.info 'CLASSPATH: %s' % $CLASSPATH


      ### start the server, wait for connections
      #
      # klass is the ejb of the config, the class EJBxx for instance
      #
      # invoke sends the request to the ejb server and waits for the ejb stub object
      # which it shares over the DRb to ActiveEJB clients
      #
      DRb.start_service(@uri, klass.invoke)
      #DRb.start_service(@uri, klass) # JUST TO MAKE DEBUG FASTER
      return DRb.thread
    end

    private

    def logger
      EJBDispatcher.logger
    end

  end
end
