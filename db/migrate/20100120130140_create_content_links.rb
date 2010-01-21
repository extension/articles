class CreateContentLinks < ActiveRecord::Migration
  def self.up
    
    # link table
    create_table "content_links", :force => true do |t|
      t.integer  "linktype"
      t.integer  "content_id"
      t.string   "content_type"
      t.string   "host", :size => 1024
      t.string   "source_host", :size => 1024
      t.string   "path", :size => 2048
      t.string   "original_fingerprint"
      t.text     "original_url"
      t.timestamps
    end
    
    add_index "content_links", ["original_fingerprint"], :unique => true
    
    
    # join table
    create_table "linkings", :force => true do |t|
      t.integer  "content_link_id"
      t.integer  "contentitem_id"
      t.string   "contentitem_type"
      t.timestamps
    end
    
    add_index "linkings", ["content_link_id","contentitem_id","contentitem_type"],  :name => "recordsignature", :unique => true
    
    
    # create links from articles
    ContentLink.reset_column_information
    Article.all.each do |a|
      ContentLink.create_from_content(a)
    end
    
    # need to set article.original_content
    execute "UPDATE articles SET original_content = REPLACE(content,'/pages/','/wiki/') WHERE original_content IS NULL"      
  end

  def self.down
    drop_table(:content_links)
    drop_table(:linkings)
  end
end
