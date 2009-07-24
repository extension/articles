# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Sponsor < ActiveRecord::Base
  serialize :cached_content_tag_data
  belongs_to :logo
  acts_as_list
  has_content_tags
  
  named_scope :prioritized, {:order => 'position ASC'}
  
  # returns an array of the names
  def cached_content_tags(force_cache_update=false)
    if(self.cached_content_tag_data.blank? or force_cache_update)
      tagarray = tags_by_ownerid_and_kind(User.systemuserid,Tag::CONTENT)
      cachedata = {}
      tagarray.map{|t| cachedata[t.id] = t.name}
      update_attribute(:cached_content_tag_data, cachedata)
      return tagarray.collect(&:name)
    else
      return self.cached_content_tag_data.collect{|id,name| name}
    end
  end  
  
end