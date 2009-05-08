class CreateTagCache < ActiveRecord::Migration
  def self.up
    create_table "cached_tags", :force => true do |t|
      t.integer "tagcacheable_id"
      t.string "tagcacheable_type"
      t.integer "taglist_kind"
      t.text "taglist"
      t.text "idlist"      
      t.timestamps
    end
  end

  def self.down
  end
end
