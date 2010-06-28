class AddLearns < ActiveRecord::Migration
  def self.up
    create_table "learn_sessions", :force => true do |t|
      t.text     "title"
      t.text     "description"
      t.datetime "session_at"
      t.text     "where"  # url could be longer than 255 chars
      t.text     "recording" # url could be longer than 255 chars
      t.integer  "created_by"
      t.integer  "last_modified_by"
      t.datetime "updated_at"
      t.datetime "created_at"
    end
    
    create_table "learn_connections", :force => true do |t|
      t.integer  "user_id"
      t.string   "email"
      t.integer  "learn_session_id"
      t.string   "connectiontype"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end

  def self.down
  end
end
