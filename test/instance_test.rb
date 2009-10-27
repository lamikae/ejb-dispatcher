require 'test/unit'
require 'yaml'
this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))
require this_dir+'/test_helper' # no helper - no init!

class InstanceTest < Test::Unit::TestCase
  def setup
    @ejbs = EJBDispatcher.ejbs
    @ports = @ejbs.collect{|ejb| ejb[1]['port']}
    flunk 'No configured EJBs!' if @ejbs.keys.size == 0
    @instances = []
  end

  def teardown
    @instances.each do |dp|
      dp.stop
    end
  end

  def test_double_start
    instance = EJBDispatcher::Instance.new()
    instance.start_thread
    i = EJBDispatcher::Instance.new()
    e = assert_raise Errno::EADDRINUSE do
      i.start_thread
    end
    assert e.message[/Address already in use/]
    instance.stop
  end

  def test_collect
    instances = @ejbs.keys.collect{|ejb| EJBDispatcher::Instance.new(ejb)}
    assert_not_nil instances
    assert_equal @ejbs.keys.size, instances.size
    # compare with EJBDispatcher
    @instances = EJBDispatcher.collect_dispatchers
    instances.each do |dp|
      assert_not_nil @instances.select{|_dp| _dp.ejb==dp.ejb}
    end
  end

  def test_config
    @instances = EJBDispatcher.collect_dispatchers
    @ejbs.each do |ejb|
      # [\"ejb21\", {\"port\"=>9874, \"class\"=>\"EJB21\", \"hostname\"=>\"localhost\"}]
      config = ejb[1]
      assert_not_nil config

      klass_str = config['class']

      # test klass is found
      klass = Kernel.const_get(klass_str)
      assert_not_nil klass

      # locate the instance
      instances = @instances.select{|dp| dp.ejb==ejb[0]}
      assert_not_nil instances
      assert_equal 1, instances.size, 'Same EJB defined multiple times'
      instance = instances.first
      assert_not_nil instance
      assert_equal klass, instance.klass
    end
  end

  def test_instance_unknown
    %w(false instances).each do |ejb|
      e = assert_raise ArgumentError do
        EJBDispatcher::Instance.new(ejb)
      end
      assert e.message[/Error while setting parameters for \"#{ejb}\"/]
    end
  end

  def test_instance_default
    instance = EJBDispatcher::Instance.new()
    assert_equal EjbObject, instance.klass
  end

  # talks with the actual dispatchers
  def test_stop_configured_ejbs
    @instances = EJBDispatcher.collect_dispatchers
    @instances.each do |dp|
      dp.start_thread
      assert dp.alive?
      assert dp.thread.alive?
      assert dp.stop
      assert !dp.alive?
      #assert dp.thread.alive? # should the thread remain alive?
      # this behaves unpredictably, how to test?
    end
  end

  def test_start_stop
    flunk_without_ejb_host

    # test client
    ejb = @ejbs.keys.first
    instance = EJBDispatcher::Instance.new(ejb)

    uri =instance.uri
    d = DRb::DRbObject.new_with_uri(uri)
    self.assert_not_nil(d)
    assert_raises DRb::DRbConnError do
      d.__ping()
    end

    thread = instance.start_thread
    assert_not_nil thread
    assert_equal thread, instance.thread
    assert thread.alive?
    assert instance.connected?
    assert_nothing_raised do
      d.__ping()
      d.__identify()
    end

    assert instance.stop
    sleep 1
    assert !instance.alive?
    assert !thread.alive?
    assert !instance.thread.alive?
    assert !instance.connected?
    # this should be off!
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

  def test_revoke
    flunk_without_ejb_host

    @instances = EJBDispatcher.collect_dispatchers
    @instances.each do |dp|
      dp.start_thread
      assert dp.alive?
      old_thread = dp.thread
      assert old_thread.alive?
      assert dp.connected?, 'Is the configured EJB working?'
      thread = dp.revoke
      assert_not_nil thread
      assert_equal Thread, thread.class
      assert dp.alive?
      assert_not_equal old_thread, dp.thread
      assert dp.thread.alive?
      assert_equal thread, dp.thread
      #       assert !old_thread.alive? # should the thread remain alive?
      # this behaves unpredictably, how to test?
    end
  end

# #   def test_halt
# #     @instances = EJBDispatcher.collect_dispatchers
# #     @instances.each do |dp|
# #       assert dp.alive?
# #       assert dp.thread.alive?
# #       dp.halt
# #       assert !dp.alive?
# #       assert !dp.thread.alive?
# #     end
# #   end

end