class PandaTables < ActiveRecord::Migration
  def self.up
    create_table "analytics", :force => true do |t|
      t.integer   "page_id"
      t.string    "label"
      t.text      "analytics_url"
      t.integer   "entrances"           
      t.integer   "bounces"           
      t.float     "bouncerate"    
      t.timestamps
    end
  end

  def self.down
    drop_table(:analytics)
  end
end
