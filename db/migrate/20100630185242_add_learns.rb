class AddLearns < ActiveRecord::Migration
  def self.up
    create_table "learn_sessions", :force => true do |t|
      t.text     "title", :null => false
      t.text     "description", :null => false
      t.datetime "session_start", :null => false
      t.datetime "session_end", :null => false
      t.text     "where"  # url could be longer than 255 chars
      t.text     "recording" # url could be longer than 255 chars
      t.integer  "created_by", :null => false
      t.integer  "last_modified_by", :null => false
      t.datetime "updated_at"
      t.datetime "created_at"
    end
    
    create_table "learn_connections", :force => true do |t|
      t.integer  "user_id"
      t.integer  "public_user_id"
      t.string   "email", :null => false
      t.integer  "learn_session_id", :null => false
      t.string   "connectiontype", :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
  end
end