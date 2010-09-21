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
    
    add_index "google_accounts", ["user_id"], :unique => true
    
    # users
    execute "INSERT INTO google_accounts (user_id, username, password, given_name, family_name, is_admin, created_at, updated_at) " + 
    "SELECT id, login, password, first_name, last_name, is_admin, NOW(), NOW() FROM users " + 
    "WHERE users.retired = 0 and users.vouched = 1 and users.id != #{User.systemuserid}"
        
    # communities integration
    add_column(:communities, :connect_to_google_apps, :boolean, :default => false)
    
    # rename computerliteracy shortname to networkliteracy
    execute "UPDATE communities SET shortname='computerliteracy' WHERE id = 68"
    
    # force a unique index, will need to enforce in code somewhere
    add_index "communities", ["shortname"], :unique => true
    
    create_table "google_groups", :force => true do |t|
      t.integer  "community_id",    :default => 0, :null => false
      t.string   "group_id",                  :null => false
      t.string   "group_name",                :null => false
      t.string   "email_permission",          :null => false
      t.datetime "apps_updated_at"
      t.boolean  "has_error",  :default => false
      t.text "last_error"
      t.timestamps
    end
    
    add_index "google_groups", ["community_id"], :unique => true
    
    # communities
    execute "INSERT INTO google_groups (community_id, group_id, group_name, email_permission, created_at, updated_at) " + 
    "SELECT id, shortname, name, 'Anyone', NOW(), NOW() FROM communities "    
    
  end

  def self.down
  end
end
