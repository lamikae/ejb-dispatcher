#!/usr/bin/env jruby
# EJB-dispatcher
# (c) Copyright 2009 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.

require 'rubygems'
require 'rake'

# Loads init and starts the dispatcher threads.
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

def env_info
  STDOUT.puts 'EJB-dispatcher' # % EJBDispatcher::VERSION
  STDOUT.puts 'Using JRuby: ' + JRUBY_VERSION
  STDOUT.puts ''
end

def usage
  STDOUT.puts 'USAGE: %s [init[name]] [start] [help]' % $0
  STDOUT.puts "
  To use EJB-dispatcher one must create a hub where to place
  all custom Ruby code and Java bytecode.

  Creating a new hub is done by calling init with a name for the hub:
    #{$0} init[name]

  After creation, cd to the newly created directory.
  There you can find a clean config/dispatcher.yml
  and folders for the code.
  "
end

application = Rake.application
application.standard_exception_handling do
  application.init

  task :help do
    env_info
    usage
  end

  task :init, [:name] do |t,args|
    if args.name.nil?
      usage
      exit 1
    end
    STDOUT.puts 'Initializing new EJB-dispatcher hub %s' % args.name
    dir = args.name

    # create directories
    require 'fileutils'
    FileUtils.mkdir_p [
      File.join(dir,"config"),
      File.join(dir,"lib","java"),
      File.join(dir,"test")
    ]

    # locate source
    file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
    vendor = File.join(
      File.dirname(File.expand_path(file)),
      '..',
      'vendor'
      )

    # copy directory
    FileUtils.copy_entry(vendor,dir)

    # show what was done
    system("tree #{dir}")
  end

  task :start do
    hub = Dir.pwd
    STDOUT.puts "Starting EJB-dispatcher hub %s" % hub
    ENV['DISPATCHER_HUB'] = hub

    # look for configuration file in hub
    config = File.join(
      hub, 'config', 'dispatcher.yml'
      )
    unless File.exists?(config)
      STDERR.puts "Configuration file was looked for at \n%s" % config
      STDERR.puts "but it could not be found - this is not a proper dispatcher hub.\n"
      usage
    else
      start_daemon
    end
    exit 1 # exit w/ error
  end

  task :default => :help

  application.top_level
end
