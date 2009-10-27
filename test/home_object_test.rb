require 'test/unit'
this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))
require this_dir+'/test_helper'

# The tests are tricky since all units cannot be tested without a live EJB server.
class HomeObjectTest < Test::Unit::TestCase

  def setup
    @ctx={
      'java.naming.factory.initial'      => 'com.evermind.server.rmi.RMIInitialContextFactory',
      'java.naming.security.principal'   => 'security_principal',
      'java.naming.security.credentials' => 'security_credentials',
      'java.naming.provider.url'         => 'rmi://provider.url/'
    }
  end

  def test_create
    e = assert_raise NativeException do
      HomeObject.new(@ctx)
    end
    assert e.message[/Unknown host/], e.message
  end

  def test_valid_ctx_keys
    val = HomeObject.validate_ctx(@ctx)
    self.assert_equal true, val
  end

  def test_invalid_ctx_keys
    ctx = @ctx.merge( {:foo => :bar} ) # invalid key :foo
    e = assert_raise Exception do
      HomeObject.validate_ctx(ctx)
    end
    self.assert e.message[/Invalid keys: \[:foo\]/], e.message
  end

end
