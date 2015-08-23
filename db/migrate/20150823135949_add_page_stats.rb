class AddPageStats < ActiveRecord::Migration
  def change
    create_table "page_stats", :force => true do |t|
      t.integer  "page_id"
      t.integer  "pageviews"
      t.integer  "unique_pageviews"
      t.integer  "weeks_published"
      t.float    "mean_pageviews"
      t.float    "mean_unique_pageviews"
      t.integer  "image_links"
      t.integer  "copwiki_images"
      t.integer  "create_images"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    add_index "page_stats", ["page_id"], :unique => true
  end

end
