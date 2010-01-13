class AddPublicAttributesCache < ActiveRecord::Migration
  def self.up
    create_table "directory_item_caches", :force => true do |t|
      t.integer  "user_id"
      t.text     "public_attributes"
      t.timestamps
    end
    
    add_index "directory_item_caches", ["user_id"]
    
  end

  def self.down
  end
end
