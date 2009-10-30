#--
# This is not an executable.
# This launches init.rb in a directory one level lower on the path as this file.
# Enables "require 'libejb-dispatcher'" to launch init and evaluate configuration
#
# See the file MIT-LICENSE included with the distribution for
# software license details.
#++

this_file = File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__
require File.dirname(File.expand_path(this_file))+'/../init'


