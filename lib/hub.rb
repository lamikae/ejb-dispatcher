# Initializes the hub environment:
#  - updates CLASSPATH from lib/java
#  - loads Ruby files from lib
#  - loads init.rb if found

vendor = ENV['DISPATCHER_HUB']
EJBDispatcher::HUB = vendor

### load vendor classes
# in pre-1.0.0 parlance, vendor equals hub.

if !vendor.nil? and File.exists?(vendor)
  vendor_lib = File.join(vendor,'lib')
  vendor_java = File.join(vendor_lib,'java')
  if File.exists?(vendor_java)
    # add vendor/lib/java to CLASSPATH, if exists
    # it may have exploded jars and plain class files.
    $CLASSPATH << vendor_java

    # include jars
    files = Dir.new(vendor_java).entries.collect do |file|
      File.join(vendor_java,file) if file[/.jar$/]
    end
    files.compact!
    files.each do |jar|
      EJBDispatcher.logger.info " (JAR)  => #{jar}"
      require "#{jar}"
#       $CLASSPATH << jar # is this necessary anymore?
    end
  end

  # load JRuby classes from vendor/lib
  if File.exists?(vendor_lib)
    files = Dir.new(vendor_lib).entries.collect do |file|
      File.join(vendor_lib,file) if file[/.rb$/]
    end
    files.compact!
    files.each do |file|
      EJBDispatcher.logger.info " (load) =) #{file}"
      require file
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
