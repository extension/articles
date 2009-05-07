class ConvertTagKindToInteger < ActiveRecord::Migration
  def self.up
    # convert taggings tag_kind from a varchar to an integer field
    
    # remove the existing index first
    remove_index(:taggings,  :name => "taggingindex")

    # rename the existing tag_kind column, add new, and set data
    rename_column(:taggings, :tag_kind, :old_tag_kind)
    add_column(:taggings, :tag_kind, :integer)
    
    # current data only has "user" and "shared" tags
    execute "UPDATE taggings SET tag_kind = CASE old_tag_kind WHEN 'user' THEN #{Tag::USER} WHEN 'shared' THEN #{Tag::SHARED} ELSE #{Tag::SYSTEM} END"
    
    # add the index back
    add_index(:taggings, ["tag_id", "taggable_id", "taggable_type", "tag_kind", "owner_id"], :name => "taggingindex", :unique => true)
    
    remove_column(:taggings, :old_tag_kind)
    
  end

  def self.down
  end
end
