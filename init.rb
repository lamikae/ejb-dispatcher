#--
# EJB-dispatcher
# (c) Copyright 2009 Mikael Lammentausta
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
this_dir = File.dirname(File.expand_path(this_file))


### load Java
require 'java'
java_lib = File.join(this_dir,'lib','java')

# set Java CLASSPATH
#   - standard jars (sniffffffff, aaaaaaah)
Dir.entries(java_lib).find_all { |f|
  $CLASSPATH << File.join(java_lib,f) if f[/.jar$/] }
#   - vendor jars are loaded later

# load standard Java classes
import java.util.Properties
import javax.naming.Context
import javax.naming.InitialContext
import javax.rmi.PortableRemoteObject

require 'logger'
require 'optparse'
require 'yaml'
require 'drb/drb'
require 'drb/timeridconv'
# DRb::TimerIdConv keeps objects alive for a certain amount of time after their last access.
# The default timeout is 600 seconds (10 minutes), and can be changed on initialization of TimerIdConv.
#
# Use TimerIdConv when you want remote objects to expire after they've been out of use for a "safe" amount of time.
DRb.install_id_conv DRb::TimerIdConv.new

# Singleton handles the homes (inefficiently at the moment)
require 'singleton'

require File.join(this_dir,'lib','ejbdispatcher')

# set HOME
EJBDispatcher::HOME = this_dir

### load logger + configuration
# first accept env variable DISPATCHER_CONFIG,
# second look in this directory
EJBDispatcher.set_logger

# EJB-dispatcher classes are loaded *before* configuration
require File.join(this_dir,'lib','ejbdispatcher','home_object')
require File.join(this_dir,'lib','ejbdispatcher','ejb_object')

# Hydra
require File.join(this_dir,'lib','hydra')
require File.join(this_dir,'lib','instance')
EJBDispatcher::Instance.extend(EJBDispatcher::ClassMethods)

EJBDispatcher.set_config


### load vendor classes
require 'find'
vendor = File.join(this_dir,'vendor')
if File.exists?(vendor) and
  vendor_lib = File.join(vendor,'lib')
  vendor_java = File.join(vendor_lib,'java')
  if File.exists?(vendor_java)
    # add vendor/lib/java to CLASSPATH, if exists
    # it may have exploded jars and plain class files.
    $CLASSPATH << vendor_java
    # include jars
    Find.find(vendor_java) do |file|
      $CLASSPATH << file if file[/.jar$/]
    end
  end

  # load JRuby classes from vendor/lib
  if File.exists?(vendor_lib)
    Find.find(vendor_lib) do |file|
      require file if file[/.rb$/]
    end
  end

  # run vendor init
  vendor_init = File.join(vendor,'init.rb')
  if File.exists?(vendor_init)
    require vendor_init
  end

else
  EJBDispatcher.logger.warn 'No vendor classes found'
end
