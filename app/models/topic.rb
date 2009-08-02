# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Topic < ActiveRecord::Base
  COMMUNITY_ASSOCIATION_CACHE_EXPIRY = 24.hours
  
  has_many :communities, :foreign_key => 'public_topic_id'
  

  
  
  # TODO: review.  This is kind of a hack that might should be done differently
  def launched_communities(forcecacheupdate=false)
    cache_key = self.class.get_object_cache_key(self,this_method,{:name => self.name})
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => COMMUNITY_ASSOCIATION_CACHE_EXPIRY) do
      self.communities(:include => :taggings, :conditions => "communities.is_launched = TRUE", :order => 'communities.public_name')
    end
  end
  
  def self.get_object_cache_key(theobject,method_name,optionshash={})
    optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
    cache_key = "#{self.name}::#{theobject.id}::#{method_name}::#{optionshashval}"
    return cache_key
  end
  
  def self.get_cache_key(method_name,optionshash={})
    optionshashval = Digest::SHA1.hexdigest(optionshash.inspect)
    cache_key = "#{self.name}::#{method_name}::#{optionshashval}"
    return cache_key
  end
  
  
  def self.topics_list(options = {},forcecacheupdate=false)
    cache_key = self.get_cache_key(this_method,options)
    Rails.cache.fetch(cache_key, :force => forcecacheupdate, :expires_in => COMMUNITY_ASSOCIATION_CACHE_EXPIRY) do
      launchedonly = options[:launchedonly].nil? ? false : options[:launchedonly]
      if(launchedonly)
        self.find(:all, :select => 'DISTINCT topics.*', :joins => [:communities], :conditions => "communities.is_launched = TRUE", :order => 'topics.name ASC')
      else
        self.find(:all, :order => 'topics.name ASC')
      end
    end
  end
  
end