class DropImageauditTables < ActiveRecord::Migration
  def up
    drop_table :community_page_stats
    drop_table :hosted_images
    drop_table :hosted_image_links
    drop_table :year_analytics
    drop_table :page_stats
  end
end
