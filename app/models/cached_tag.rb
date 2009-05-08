# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class CachedTag < ActiveRecord::Base
  belongs_to :tagcacheable, :polymorphic => true
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def create_or_update_with_tagarray(tagcacheable,taglist_kind,tagarray)
      taglist = tagarray.map(&:name).join(Tag::JOINER)
      tagidlist = tagarray.map(&:id).join(Tag::JOINER)
      find_object = self.find(:first, :conditions => {:tagcacheable_type => tagcacheable.class.name,:tagcacheable_id => tagcacheable.id, :taglist_kind => taglist_kind})
      if(find_object.nil?)
        find_object = create(:tagcacheable => tagcacheable, :taglist_kind => taglist_kind, :taglist => taglist, :idlist => tagidlist)
      else
        find_object.update_attributes({:taglist => taglist, :idlist => tagidlist})
      end
      return find_object
    end
    
  end
end