class AddYetAnotherLogTable < ActiveRecord::Migration
  def self.up
    create_table "page_updates", :force => true do |t|
      t.integer  "user_id"
      t.integer  "page_id"
      t.datetime "created_at",                                         :null => false
      t.string   "action",                                             :null => false
      t.string   "remote_addr", :limit => 20, :default => "127.0.0.1"
    end

    add_index "page_updates", ["page_id"]
    add_index "page_updates", ["user_id"]
    
  end

  def self.down
  end
end
