# adding method to Kernel in order to use it as a cache key later
module Kernel
private
   def this_method
     caller[0] =~ /`([^']*)'/ and $1
   end
end
