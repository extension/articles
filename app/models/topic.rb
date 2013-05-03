# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Topic < ActiveRecord::Base
  COMMUNITY_ASSOCIATION_CACHE_EXPIRY = 24.hours
  
  has_many :publishing_communities, :foreign_key => 'public_topic_id', :order => 'publishing_communities.public_name'
  
  def launched_communities(forcecacheupdate=false)
    self.publishing_communities(:include => :taggings, :conditions => "publishing_communities.is_launched = TRUE", :order => 'publishing_communities.public_name')
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
    launchedonly = options[:launchedonly].nil? ? false : options[:launchedonly]
    if(launchedonly)
      self.find(:all, :select => 'DISTINCT topics.*', :include => [:publishing_communities], :conditions => "publishing_communities.is_launched = TRUE", :order => 'topics.name ASC, publishing_communities.public_name')
    else
      self.find(:all, :select => 'DISTINCT topics.*', :include => [:publishing_communities], :order => 'topics.name ASC, publishing_communities.public_name')
    end
  end
  
end