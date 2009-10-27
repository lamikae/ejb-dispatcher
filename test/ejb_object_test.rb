require 'test/unit'
this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))
require this_dir+'/test_helper'

class TestEJB_A < EjbObject
  set_jndi_name 'TestEJB_A'
  set_bean_home_class 'TestEJB_AHome'
  set_security_principal 'guestA'
  set_security_credentials 'guestA'
  set_provider_url 'ormi://localhost:1025/TestEJB_A'
end

class TestEJB_B < EjbObject
  set_jndi_name 'TestEJB_B'
  set_security_principal 'guestB'
  set_security_credentials 'guestB'
  set_provider_url 'ormi://localhost:1025/TestEJB_B'
end

class EjbObjectTest < Test::Unit::TestCase
  def setup
    super
  end

  def test_new
    e = assert_raise NativeException do
      TestEJB_A.new
    end
    assert e.message[/Connection refused/], e.message
  end

  def test_attributes
    assert_equal 'TestEJB_A', TestEJB_A.jndi_name
    assert_equal 'TestEJB_AHome', TestEJB_A.bean_home_class
    env = {
      'java.naming.factory.initial'      => 'com.evermind.server.rmi.RMIInitialContextFactory',
      'java.naming.security.principal'   => 'guestA',
      'java.naming.security.credentials' => 'guestA',
      'java.naming.provider.url'         => 'ormi://localhost:1025/TestEJB_A'
    }
    assert_equal env, TestEJB_A.context_environment

    assert_equal 'TestEJB_B', TestEJB_B.jndi_name
    assert_nil TestEJB_B.bean_home_class
    env = {
      'java.naming.factory.initial'      => 'com.evermind.server.rmi.RMIInitialContextFactory',
      'java.naming.security.principal'   => 'guestB',
      'java.naming.security.credentials' => 'guestB',
      'java.naming.provider.url'         => 'ormi://localhost:1025/TestEJB_B'
    }
    assert_equal env, TestEJB_B.context_environment
  end

end