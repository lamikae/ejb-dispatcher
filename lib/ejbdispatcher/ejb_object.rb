# Proxy for the EJBObject stub.
#
# The stub is the EJB interface. Any method not directed to the class itself is directed to the stub.
class EjbObject

  class << self

    public

    # Sets +jndi_name+
    def set_jndi_name(value)
      define_attr_method :jndi_name, value
    end

    # Sets +bean_home_class+
    def set_bean_home_class(value)
      define_attr_method :bean_home_class, value
    end
    # default
    def bean_home_class # :nodoc:
      nil
    end

    # Sets java.naming.security.principal
    def set_security_principal(value)
      define_attr_method :security_principal, value
    end

    # Sets java.naming.security.credentials
    def set_security_credentials(value)
      define_attr_method :security_credentials, value
    end

    # Sets java.naming.provider.url
    def set_provider_url(value)
      define_attr_method :provider_url, value
    end

    # Formulates a context Hash for HomeObject from settings.
    def context_environment
      {
        'java.naming.factory.initial'      => 'com.evermind.server.rmi.RMIInitialContextFactory',
        'java.naming.security.principal'   => security_principal,
        'java.naming.security.credentials' => security_credentials,
        'java.naming.provider.url'         => provider_url
      }
    end

    # The initializer calls create() on the Bean home interface,
    # which invokes the actual bean, and returns the Bean stub interface.
    #
    # The EjbObject wraps the stub and exposes the EJB methods to Ruby.
    def invoke(*args)
      begin
        self.new(*args)
      rescue
        logger.error $!.message
        return nil
      end
    end

    protected

    def logger
      EJBDispatcher.logger
    end

    public

    # Defines class methods from vendor models for this instance of the EJB.
    #
    # All instances of this particular EJB will then share this method.
    # TODO: DRY up, duplicate method in EJBDispatcher
    def define_attr_method(name, value=nil)
      #logger.debug 'Defining %s' % name
      (class << self; self; end).class_eval "def #{name}; #{value.to_s.inspect}; end"
    end

  end

  public

  # Creates an instance that reads its connection values from the class.
  # Calls the 'create' method on the home interface stub.
  # This invokes create() on the actual bean, and returns the stub interface.
  def initialize(home=nil)
    logger.debug 'Initializing %s' % self.class.jndi_name
    # request new EJB home, unless one was given.
    home ||= request_home(self.class.context_environment)
    logger.debug 'Home: %s' % home.inspect
    @ejbhome = home
    # this is the EJB home for jndi_name
    @home = @ejbhome.lookup(self.class.jndi_name,self.class.bean_home_class)
    logger.debug 'Initializing EjbObject from %s' % @home.java_object.inspect
    # actually, re-defining self would be better option, since EjbObject proxies the @stub.
    @stub = @home.create
  end

  # when the DRb service is restated and EJB revoked, the ejbhome is still the same.
  # the +Instance#revoke+ method takes this object and initialize another Instance with it.
  #
  # Returns @ejbhome
  def __ejbhome
    return @ejbhome
  end

  # Returns @home
  def __home
    return @home
  end

  # For testing connection from ActiveEJB
  def __ping
    logger.debug 'Respond to ping'
    return true
  end
  
  # For getting to know the server from ActiveEJB
  def __identify
    id = 'EJB-dispatcher %s connected to %s' % [
      EJBDispatcher::VERSION,
      @stub.java_object
    ]
    logger.debug 'Identify as %s' % id
    return id
  end
  
  protected

  # Home interface stub for the JavaBean.
  # The Bean is created through this Java interface.
  def request_home(ctx)
    HomeObject.new(ctx)
  end

  # Calls the method on the EJB stub.
  def method_missing(method, *args, &block)
    logger.debug 'Calling EJB stub with %s' % method
    obj=@stub.send(method, *args, &block)
    # object returned by EJB
    logger.debug 'EJB returned: %s' % obj.inspect

    return obj
  end

  def logger
    EJBDispatcher.logger
  end

end
