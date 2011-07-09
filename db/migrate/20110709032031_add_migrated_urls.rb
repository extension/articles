class AddMigratedUrls < ActiveRecord::Migration
  def self.up
    create_table "migrated_urls", :force => true do |t|
      t.string   "alias_url"
      t.string   "alias_url_fingerprint"
      t.string   "target_url"
      t.string   "target_url_fingerprint"
    end
  end 
  
  def self.down
    drop_table(:migrated_urls)
  end
end
  
