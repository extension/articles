# === COPYRIGHT:
#  Copyright (c) North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file

module CacheTools

  def self.included(base)
    base.extend(self)
  end

  # assumes activerecord - just make sure there's something
  # that responds to self.id if this is happening on an 
  # instance
  def get_cache_key(method_name,optionshash={})
   optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
   if(self.is_a?(Class))
     cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
   else
     cache_key = "#{self.class.name}##{self.id}::#{method_name}::#{optionshashval}"
   end    
   return cache_key
  end

end