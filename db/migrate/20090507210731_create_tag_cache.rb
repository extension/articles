class CreateTagCache < ActiveRecord::Migration
  def self.up
    create_table "tag_caches", :force => true do |t|
      t.integer "tagcacheable_id"
      t.string "tagcacheable_type"
      t.integer "cached_kind"
      t.text "cached_tags"
      t.text "cached_ids"      
      t.timestamps
    end
  end

  def self.down
  end
end
