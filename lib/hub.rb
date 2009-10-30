# Initializes the hub environment:
#  - updates CLASSPATH from lib/java
#  - loads Ruby files from lib
#  - loads init.rb if found

vendor = ENV['DISPATCHER_HUB']
EJBDispatcher::HUB = vendor

### load vendor classes
require 'find'

if !vendor.nil? and File.exists?(vendor)
  vendor_lib = File.join(vendor,'lib')
  vendor_java = File.join(vendor_lib,'java')
  if File.exists?(vendor_java)
    # add vendor/lib/java to CLASSPATH, if exists
    # it may have exploded jars and plain class files.
    $CLASSPATH << vendor_java
    # include jars
    Find.find(vendor_java) do |file|
      if file[/.jar$/]
        EJBDispatcher.logger.info " (JAR)  => #{file}"
        $CLASSPATH << file
      end
    end
  end

  # load JRuby classes from vendor/lib
  if File.exists?(vendor_lib)
    Find.find(vendor_lib) do |file|
      if file[/.rb$/]
        EJBDispatcher.logger.info " (load) =) #{file}"
        require file
      end
    end
  end

  # run vendor init
  vendor_init = File.join(vendor,'init.rb')
  if File.exists?(vendor_init)
    EJBDispatcher.logger.info " (init) =D #{vendor_init}"
    require vendor_init
  end

else
  EJBDispatcher.logger.warn 'No vendor classes found'
end
