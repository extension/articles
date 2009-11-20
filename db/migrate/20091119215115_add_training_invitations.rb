class AddTrainingInvitations < ActiveRecord::Migration
  def self.up
      
    create_table "training_invitations", :force => true do |t|
      t.string   "email",                          :null => false
      t.integer  "user_id"
      t.integer  "created_by"
      t.datetime "completed_at"
      t.datetime "expires_at"
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  
    add_index "training_invitations", ["email"], :unique => true
  
  end
  


  def self.down
  end
end
