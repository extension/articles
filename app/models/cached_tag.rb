# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class CachedTag < ActiveRecord::Base
  # tag kinds are from the tag model
  # cached kinds - so that later we might cache "top" tags
  ALL = 0
  TOP = 1
  
  belongs_to :tagcacheable, :polymorphic => true
  serialize :cachedata
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def create_or_update(tagcacheable,ownerid,tag_kind)
      tagacheable.taggable?(true)
      tagarray = tagcacheable.tags_by_kind(kind)
      fulltextlist = tagarray.map(&:name).join(Tag::JOINER)
      find_object = self.find(:first, :conditions => {:tagcacheable_type => tagcacheable.class.name,:tagcacheable_id => tagcacheable.id, :owner_id => ownerid, :tag_kind => tag_kind})
      if(find_object.nil?)
        find_object = create(:tagcacheable => tagcacheable, :owner_id => ownerid, :tag_kind => tag_kind, :fulltextlist => fulltextlist, :cachedata => tagarray)
      else
        find_object.update_attributes({:fulltextlist => fulltextlist, :cachedata => tagarray})
      end
      return find_object
    end
    
  end
end