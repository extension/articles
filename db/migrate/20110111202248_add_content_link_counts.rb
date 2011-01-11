class AddContentLinkCounts < ActiveRecord::Migration
  def self.up
    create_table "content_link_stats", :force => true do |t|
      t.integer  "content_id"
      t.integer  "total"
      t.integer  "external"
      t.integer  "internal"
      t.integer  "wanted"
      t.integer  "local"
      t.integer  "broken"
      t.integer  "warning"
      t.integer  "redirected"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    
    add_index("content_link_stats", "content_id")
  end

  def self.down
  end
end
