class CreateApiKeys < ActiveRecord::Migration
  def self.up
    create_table "api_keys", :force => true do |t|
      t.integer  "user_id"
      t.string   "name"
      t.string   "keyvalue"
      t.integer  "created_by"
      t.boolean  "enabled"
      t.datetime "created_at"
    end
    
    add_index "api_keys", ["user_id","name"], :unique => true
    add_index "api_keys", ["keyvalue"], :unique => true
    
    # create a "system" apikey for logging purposes
    execute "INSERT INTO api_keys (user_id,name,keyvalue,created_by,enabled,created_at) SELECT 1,'system','system',1,1,NOW()"
    
    # note, IP address should probably transition to an integer in the future, leaving as string for now
    create_table "api_key_events", :force => true do |t|
      t.integer  "api_key_id"
      t.string   "requestaction"
      t.string   "ipaddr",                 :limit => 20
      t.text     "additionaldata"
      t.datetime "created_at"
    end
    
    add_index "api_key_events", ["api_key_id","created_at"]
      
  end

  def self.down
    drop_table("api_keys")
    drop_table("api_key_events")
  end
end
