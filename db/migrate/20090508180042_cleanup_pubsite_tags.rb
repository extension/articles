class CleanupPubsiteTags < ActiveRecord::Migration
  def self.up
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
