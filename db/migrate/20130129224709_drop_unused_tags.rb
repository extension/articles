class DropUnusedTags < ActiveRecord::Migration
  def self.up
    execute "DELETE tags.* from tags left join taggings on taggings.tag_id = tags.id where taggings.id is NULL"
  end

  def self.down
  end
end
