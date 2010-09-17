class GoogleAppsIntegration < ActiveRecord::Migration
  def self.up
    
    create_table "google_accounts", :force => true do |t|
      t.integer  "user_id",    :default => 0, :null => false
      t.string   "username",                  :null => false
      t.boolean  "no_sync_password",  :default => false
      t.string   "password",                  :null => false
      t.string   "given_name",                :null => false
      t.string   "family_name",               :null => false
      t.boolean  "is_admin",  :default => false
      t.boolean  "suspended",  :default => false
      t.datetime "apps_updated_at"
      t.boolean  "has_error",  :default => false
      t.text "last_error"
      t.timestamps
    end
    
  end

  def self.down
  end
end
