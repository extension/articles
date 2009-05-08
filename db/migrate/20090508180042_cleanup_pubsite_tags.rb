class CleanupPubsiteTags < ActiveRecord::Migration
  # this is so absurd
  class PubsiteTag < ActiveRecord::Base; end
  
  def self.up
    
    # holdover: need to pull over community tags
    pts = PubsiteTag.find(:all, :conditions => "community_id IS NOT NULL")
    pts.each do |pt|
      c = Community.find_by_id(pt.community_id)
      if(!c.nil?)
        c.tag_with(pt.name,User.systemuserid,Tag::CONTENT)
      end
    end
    
    drop_table(:pubsite_tags)
    drop_table(:pubsite_taggings)
    remove_column(:articles,:cached_tag_list)
    remove_column(:events,:cached_tag_list)
    # bonus, drop the communities tag cache
    remove_column(:communities,:taglist_cache)
  end

  def self.down
  end
end
