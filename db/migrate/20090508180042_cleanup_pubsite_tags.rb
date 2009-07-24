class CleanupPubsiteTags < ActiveRecord::Migration
  class PubsiteTag < ActiveRecord::Base; end
  
  def self.up
    
    # having to modify this after the fact (20090723) to deal with advertisement, nee, sponsors tags
    rename_table(:advertisements, :sponsors)
        
    # get the pubsite tag id's out of the sponsors model
    Sponsor.all.each do |sponsor|
      # find the pubsite tag name, and then tag with that name
      pt = PubsiteTag.find(sponsor.tag_id)
      sponsor.tag_with(pt.name,User.systemuserid,Tag::CONTENT)
    end
    
    # drop the tag_id column from Sponsors
    remove_column(:sponsors, :tag_id)
        
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
