class AddCommunityImageStats < ActiveRecord::Migration
  def change
    create_table "community_page_stats", :force => true do |t|
      t.integer  "publishing_community_id"
      t.integer  "pages"
      t.integer  "viewed_pages"
      t.integer  "missing_pages"
      t.text     "viewed_percentiles"
      t.integer  "image_links"
      t.integer  "copwiki_images"
      t.integer  "create_images"
      t.integer  "hosted_images"
      t.integer  "copwiki_images_with_copyright"
      t.integer  "create_images_with_copyright"
      t.integer  "hosted_images_with_copyright"
      t.datetime "created_at",       :null => false
      t.datetime "updated_at",       :null => false
    end

    add_index "community_page_stats", ["publishing_community_id"], :unique => true


  end
end
