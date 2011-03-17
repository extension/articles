class PandaTables < ActiveRecord::Migration
  def self.up
    create_table "analytics", :force => true do |t|
      t.integer   "page_id"
      t.string    "datalabel"
      t.date      "start_date"
      t.date      "end_date"
      t.text      "analytics_url"
      t.string    "analytics_url_hash"
      t.integer   "entrances"           
      t.integer   "bounces"           
      t.float     "bouncerate"    
      t.timestamps
    end
    
    add_index "analytics", ["analytics_url_hash"], :name => "recordsignature", :unique => true
    add_index "analytics", ["page_id"]
  end

  def self.down
    drop_table(:analytics)
  end
end
