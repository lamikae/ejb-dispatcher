require 'test/unit'
require 'yaml'
this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))
require this_dir+'/test_helper'

require 'timeout'

# Tests the actual configuration.
class HydraTest < Test::Unit::TestCase
  def setup
    @ports = EJBDispatcher.ejbs.collect{|ejb| ejb[1]['port']}
    # assert that no port is listening
    assert_equal [false]*@ports.size, listening_ports(@ports).values,
        'The configured DRb ports (%s) should not be reserved' % @ports.join(', ')

    @hydra = Hydra.new
    self.assert_not_nil(@hydra)
    assert @hydra.alive?
  end

  def teardown
    @hydra.stop if @hydra
  end

  # Takes in parameter an Array of ports.
  # Returns a Hash, where the keys are the ports, each with a boolean value.
  def listening_ports(ports)
    ret = {}
    ports.each do |port|
      tcp = %x[netstat -anp 2>/dev/null | grep #{port}]
      ret[port] = tcp[/LISTEN/].nil? ? false : true
    end
    return ret
  end

  def ports_are_listening(ports)
    ports.each do |port|
      tcp = %x[netstat -anp 2>/dev/null | grep #{port}]
      return false unless tcp[/LISTEN/]
    end
    return true
  end

  def ports_are_not_listening(ports)
    ports.each do |port|
      tcp = %x[netstat -anp 2>/dev/null | grep #{port}]
      return false if tcp[/LISTEN/]
    end
    return true
  end

  def test_threads
    @hydra.dispatchers.each_with_index do |dp,i|
      self.assert_equal(@hydra.threads[i], dp.thread)
      self.assert dp.alive?
      self.assert dp.connected?
    end
  end

  # this test combines starting, testing ports and stop to speed up testing with slow ejbs
  def test_start_ports_stop
    self.assert_equal(0,@hydra.dispatchers.size)
    assert @hydra.start_threads
    self.assert_equal(EJBDispatcher.ejbs.size,@hydra.dispatchers.size)
    assert ports_are_listening(@ports)

    dispatchers = @hydra.dispatchers
    threads = @hydra.threads
    assert @hydra.stop
    assert ports_are_not_listening(@ports), 'Some ports are still listening'

    self.assert_equal(1,@hydra.dispatchers.size, 'Wrong number of dispatchers')
    self.assert_equal(1,@hydra.threads.size, 'Wrong number of threads')
    dispatchers.each do |dp|
      assert !dp.alive?
      assert !dp.connected?
    end

    flunk_without_ejb_host

    # test client (should not respond)
    @ports.each do |port|
      uri = 'druby://localhost:%s' % port
      d = DRb::DRbObject.new_with_uri(uri)
      self.assert_not_nil(d)
      begin
        d.__ping()
        flunk 'DRb server should be off, but it is still responding'
      end
      assert_raises DRb::DRbConnError do
        d.__ping()
      end
      assert_raises DRb::DRbConnError do
        d.__identify()
      end
    end
  end

  def test_revoke
    assert @hydra.start_threads
    boot_at = @hydra.boot_at
    dispatchers = @hydra.dispatchers
    assert_nothing_raised do
      assert @hydra.revoke
    end
    self.assert_equal boot_at, @hydra.boot_at
    self.assert_equal dispatchers.size, @hydra.dispatchers.size
    assert ports_are_listening(@ports)

    flunk_without_ejb_host

    # test client
    @ports.each do |port|
      uri = 'druby://localhost:%s' % port
      d = DRb::DRbObject.new_with_uri(uri)
      self.assert_not_nil(d)
      assert_nothing_raised do
        d.__ping()
        d.__identify()
      end
    end
  end

end