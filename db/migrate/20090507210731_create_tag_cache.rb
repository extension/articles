class CreateTagCache < ActiveRecord::Migration
  def self.up
    create_table "cached_tags", :force => true do |t|
      t.integer "tagcacheable_id"
      t.string "tagcacheable_type"
      t.integer "owner_id"
      t.integer "tag_kind"
      t.integer "cache_kind"
      t.text "fulltextlist"
      t.text "cachedata"      
      t.timestamps
    end
  end

  def self.down
  end
end
