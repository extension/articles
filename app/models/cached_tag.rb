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
  
  named_scope :content, {:conditions => "owner_id = #{User.systemuserid} and tag_kind = #{Tag::CONTENT}"}
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
    
  def self.create_or_update(tagcacheable,ownerid,tag_kind)
    tagarray = tagcacheable.tags_by_ownerid_and_kind(ownerid,tag_kind)
    fulltextlist = tagarray.map(&:name).join(Tag::JOINER)
    cachedata = {}
    tagarray.map{|t| cachedata[t.id] = {:name => t.name, :frequency => t.frequency}}
    find_object = self.find(:first, :conditions => {:tagcacheable_type => tagcacheable.class.name,:tagcacheable_id => tagcacheable.id, :owner_id => ownerid, :tag_kind => tag_kind})
    if(find_object.nil?)
      find_object = create(:tagcacheable => tagcacheable, :owner_id => ownerid, :tag_kind => tag_kind, :fulltextlist => fulltextlist, :cachedata => cachedata)
    else
      find_object.update_attributes({:fulltextlist => fulltextlist, :cachedata => cachedata})
    end
    return find_object
  end
  
  def self.rebuild_all(cacheabletype,ownerid = User.anyuser,tag_kind = Tag::ALL)
    if(cacheabletype.is_a?(Class) and cacheabletype.instance_methods.include?('cached_tags'))
      cacheabletype.all.each do |item|
        self.create_or_update(item,ownerid,tag_kind)
      end
    end
  end
    
end