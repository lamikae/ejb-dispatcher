# Threading for individual DRb servers. One for each EJB.
#
class Hydra

  attr_reader :dispatchers, :boot_at

  # Starts the threads by calling private method start_threads().
  def initialize
    logger.info 'PPID: %i' % Process.pid
    @dispatchers = []
    @boot_at = Time.now
  end

  # Collects @dispatchers and starts the dispatcher threads.
  # Returns true.
  def start_threads
    @dispatchers = EJBDispatcher.collect_dispatchers
    ret = true
    @dispatchers.each do |dp|
      thread = dp.start_thread
      unless thread.alive?
        logger.error 'Thread for EJB %s failed to start' % dp.ejb
        ret = false
      end
    end
    logger.info 'Ready'
    return ret
  end

  # Collects the threads from @dispatchers
  def threads
    threads = []
    @dispatchers.each do |dp|
      threads << dp.thread
    end
    return threads
  end

  # Stops the threads.
  def stop
    unless @dispatchers.any?
      EJBDispatcher.logger.debug 'All threads are terminated'
      return false
    else
      EJBDispatcher.logger.info 'Hydra is stopping'
      @dispatchers.each { |dp| dp.stop }
      @boot_at = nil
    end
    logger.info 'Ready'
    return true
  end

  # Called at signal USR2.
  # Calls each Instance#revoke()
  def revoke
    logger.info 'Hydra is revoking the dispatchers'
    @dispatchers.each { |dp| dp.revoke }
    logger.info 'Ready'
    return true
  end

  # True if all the instance threads are alive
  def alive?
    @dispatchers.each do |dp|
      return false unless dp.alive?
    end
    return true
  end

  def logger
    EJBDispatcher.logger
  end

end
