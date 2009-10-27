#!/usr/bin/env jruby
# EJB-dispatcher
# (c) Copyright 2009 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.

require 'rubygems'
require 'rake'

# Loads init and starts the Hydra.
def start_daemon
  # load init
  file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
  this_dir = File.dirname(File.expand_path(file))
  require File.join(this_dir,'..','init')

  EJBDispatcher.logger.info 'Starting EJB dispatcher %s' % EJBDispatcher::VERSION
  EJBDispatcher.logger.debug 'JRuby: %s, targeting Ruby spec %s' % [JRUBY_VERSION,RUBY_VERSION]

  # Initialize Hydra and start the dispatcher threads
  hydra = Hydra.new
  hydra.start_threads

  # Trap signal USR2, which will revoke all EJBs.
  #
  # To activate the trap of process $PPID:
  #   kill -USR2 $PPID
  while(true) do
    trap("USR2") {
      EJBDispatcher.logger.info 'Trapped USR2 - revoking'
      hydra.revoke
    }
    sleep 5
  end
end

application = Rake.application
application.standard_exception_handling do
  application.init

  task :usage do
    STDOUT.puts 'EJB dispatcher' # % EJBDispatcher::VERSION
    STDOUT.puts 'JRuby: %s, targeting Ruby spec %s' % [JRUBY_VERSION,RUBY_VERSION]
    STDOUT.puts ''
    STDOUT.puts 'USAGE:'
  end

  task :init do
    STDOUT.puts 'Initializing new EJB-dispatcher hub (TODO)'
  end

  task :start do
    start_daemon
    exit 1 # exit w/ error
  end

  task :default => :usage

  application.top_level
end
