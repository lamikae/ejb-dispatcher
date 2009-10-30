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
include Java
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
require File.join(this_dir,'lib','ejb')

# set HOME
EJBDispatcher::HOME = this_dir

### load logger
EJBDispatcher.set_logger

# EJB-dispatcher classes are loaded *before* configuration
require File.join(this_dir,'lib','ejbdispatcher','home_object')
require File.join(this_dir,'lib','ejbdispatcher','ejb_object')

# Load hub environment
require File.join(this_dir,'lib','hub')

# Prepare Hydra
require File.join(this_dir,'lib','hydra')
require File.join(this_dir,'lib','instance')
EJBDispatcher::Instance.extend(EJBDispatcher::ClassMethods)

# Load configuration
EJBDispatcher.set_config
