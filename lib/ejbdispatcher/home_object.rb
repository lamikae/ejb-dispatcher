# Static class for lookup of a remote EJB Home.
class HomeObject

  attr_reader :context

  def initialize(ctx)
    logger.debug 'Initializing HomeObject: %s' % ctx.inspect
    self.class.validate_ctx(ctx)
    @context = self.initial_context(ctx)
  end

  class << self
    def logger
      EJBDispatcher.logger
    end

    def context_keys
      [
        'java.naming.factory.initial',
        'java.naming.security.principal',
        'java.naming.security.credentials',
        'java.naming.provider.url'
      ]
    end

    # Validates context keys in the ruby Hash.
    # Any unknown key raises an Exception.
    #
    # public method for testing purposes.
    def validate_ctx(ctx)
      logger.debug 'Validating %s' % ctx.keys.inspect
      # any unknown key raises an Exception
      invalid_keys = (ctx.keys | context_keys) - context_keys
      if invalid_keys.any?
        msg = 'Invalid keys: %s' % invalid_keys.inspect
        logger.debug msg
        raise Exception, msg
      end
      return true
    end

  end

  public
    
  # Initializes context and requests the JavaBean Home.
  #
  # Params:
  #   - jndi_name       (String)
  #   - bean_home_class (String)
  #     If class narrowing is needed to locate the proper Home object, define bean_home_class
  def lookup(jndi_name,bean_home_class=nil)
    logger.debug 'Lookup of %s' % jndi_name
    home = @context.lookup(jndi_name)
    #logger.debug 'HomeObject found: %s (%s)' % [ jndi_name,bean_home_class ]

    if bean_home_class
      ### Same Host, Different Context: Remote Home
      #
      # Note: unlike the Local Home Interface example, the reference to the Remote Home Interface is a conventional JNDI 
      # name that is generated by WSAD and is visible in the object's Deployment Desciptor.  It is because WSAD generates
      # a JNDI name to this interface, not the Local interface, that one must use the Reference form shown above.
      #
      # Note also, that the object obtained is a stub delivered through IIOP, a CORBA protocol used to support 
      # remote procedure calls.  Consequently, it must be converted to a conventional Java object from its CORBA form;
      # this is done through the process of narrowing.
      #
      # http://www.cs.unc.edu/Courses/jbs/lessons/enterprise/ejb_jndi/
      return PortableRemoteObject.narrow(
        home,
        Kernel.const_get(bean_home_class).java_class
        )
    else
      return home
    end
  end

  protected

  # Sets up an initial context that can be used for looking up JNDI names.
  def initial_context(ctx)
    InitialContext.new(self.properties(ctx))
  end

  # Converts the ruby context Hash to java.util.Properties.
  def properties(ctx)
    properties = Properties.new()
    ctx.each { |key, value| properties.put(key, value) }
    return properties
  end


  def logger
    self.class.logger
  end

end
