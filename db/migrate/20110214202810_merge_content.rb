class MergeContent < ActiveRecord::Migration
  def self.up    
    create_table "pages", :force => true do |t|
      t.string   "datatype"
      t.boolean  "indexed", :default => true
      t.text     "title"
      t.string   "url_title", :limit => 101
      t.text     "content",          :limit => 16777215
      t.text     "original_content", :limit => 16777215
      t.datetime "source_created_at"
      t.datetime "source_updated_at"
      t.string   "source"
      t.string   "source_id"
      t.string   "source_revision"
      t.text     "source_url"
      t.string   "source_url_fingerprint"
      t.boolean  "is_dpl",                               :default => false
      t.text     "reference_pages"
      t.integer  "migrated_id"
      t.boolean  "has_broken_links"
      t.text     "coverage"
      t.text     "state_abbreviations"
      t.datetime "event_start"
      t.string   "time_zone"
      t.text     "event_location"
      t.integer  "event_duration"
      t.datetime "created_at"
      t.datetime "updated_at"  
    end

    add_index "pages", ["datatype"]
    add_index "pages", ["migrated_id"]
    add_index "pages", ["title"], :length => {"title"=>"255"}
    add_index "pages", ["source_created_at", "source_updated_at"]
    add_index "pages", ["event_start"]
    add_index "pages", ["source_url_fingerprint"], :unique => true
    
    
    # articles        
    article_query = "INSERT INTO pages (id,datatype,title,content,original_content,source_created_at,source_updated_at,source_url,source_url_fingerprint,is_dpl,has_broken_links,created_at,updated_at)"
    article_query += " SELECT id,'Article',title,content,original_content,wiki_created_at,wiki_updated_at,original_url,SHA1(original_url),is_dpl,has_broken_links,created_at,updated_at  FROM articles"
    execute article_query
    
    # get a "source id" for articles
    execute "UPDATE pages SET source = 'copwiki', source_id = REPLACE(source_url,'http://cop.extension.org/wiki/','') WHERE source_url LIKE 'http://cop.extension.org/wiki/%'"
    execute "UPDATE pages SET source = 'eorganic', source_id = REPLACE(source_url,'http://eorganic.info/node/','') WHERE source_url LIKE 'http://eorganic.info/node/%'"
    execute "UPDATE pages SET source = 'eorganic', source_id = REPLACE(source_url,'http://eorganic.info/taxonomy/term/','') WHERE source_url LIKE 'http://eorganic.info/taxonomy/term/%'"
    execute "UPDATE pages SET source = 'pbgworks', source_id = REPLACE(source_url,'http://pbgworks.org/node/','') WHERE source_url LIKE 'http://pbgworks.org/node/%'"
    execute "UPDATE pages SET source = 'pbgworks', source_id = REPLACE(source_url,'http://pbgworks.org/menu/','') WHERE source_url LIKE 'http://pbgworks.org/menu/%'"
    
    
    # turn news into a datatype and set index false
    # get the id for the news bucket
    news_bucket = ContentBucket.find_by_name('news')
    execute "UPDATE pages,bucketings SET pages.datatype = 'News', pages.indexed = 0 WHERE bucketings.bucketable_id = pages.id AND bucketings.bucketable_type = 'Article' AND bucketings.content_bucket_id = #{news_bucket.id}"
    # set indexed to true for originalnews
    originalnews_bucket = ContentBucket.find_by_name('originalnews')
    execute "UPDATE pages,bucketings SET pages.indexed = 1 WHERE bucketings.bucketable_id = pages.id AND bucketings.bucketable_type = 'Article' AND bucketings.content_bucket_id = #{originalnews_bucket.id}"
    
    
    # faqs
    faq_query = "INSERT INTO pages (source,datatype,title,content,original_content,source_created_at,source_updated_at,source_url,source_url_fingerprint,reference_pages,migrated_id,source_id,created_at,updated_at)"
    faq_query += " SELECT 'copfaq','Faq',question,answer,answer,heureka_published_at,heureka_published_at,CONCAT('http://cop.extension.org/publish/show/',id),SHA1(CONCAT('http://cop.extension.org/publish/show/',id)),reference_questions,id,id,created_at,updated_at FROM faqs"
    execute faq_query

    # events
    event_query = "INSERT INTO pages (source,datatype,title,content,original_content,source_created_at,source_updated_at,source_url,source_url_fingerprint,migrated_id,source_id,created_at,updated_at,coverage,state_abbreviations,event_start,time_zone,event_location,event_duration)"
    event_query += " SELECT 'copevents','Event',title,description,description,xcal_updated_at,xcal_updated_at,CONCAT('http://cop.extension.org/events/',id),SHA1(CONCAT('http://cop.extension.org/events/',id)),id,id,created_at,updated_at,coverage,state_abbreviations,start,time_zone,location,duration FROM events"
    execute event_query
    
    
    
    # taggings, have to drop the index temporarily
    remove_index(:taggings,  :name => "taggingindex")
    add_column(:taggings,:old_taggable_type,:string)
    add_column(:taggings,:old_taggable_id,:integer)
    execute "UPDATE taggings SET old_taggable_type = taggable_type,old_taggable_id = taggable_id"
    
    # clean up empty taggings
    # articles
    execute "DELETE taggings.* FROM taggings, (SELECT taggings.id as tagging_id from taggings LEFT JOIN articles ON taggings.taggable_id = articles.id WHERE taggings.taggable_type = 'Article' and articles.id is NULL) as empty_taggings where taggings.id = empty_taggings.tagging_id"
    # faqs
    execute "DELETE taggings.* FROM taggings, (SELECT taggings.id as tagging_id from taggings LEFT JOIN faqs ON taggings.taggable_id = faqs.id WHERE taggings.taggable_type = 'Faq' and faqs.id is NULL) as empty_taggings where taggings.id = empty_taggings.tagging_id"
    # events
    execute "DELETE taggings.* FROM taggings, (SELECT taggings.id as tagging_id from taggings LEFT JOIN events ON taggings.taggable_id = events.id WHERE taggings.taggable_type = 'Event' and events.id is NULL) as empty_taggings where taggings.id = empty_taggings.tagging_id"
        
    # faq taggings
    execute "UPDATE taggings,pages SET taggings.taggable_id = pages.id WHERE taggings.taggable_id = pages.migrated_id AND taggings.taggable_type = 'Faq' and pages.datatype = 'Faq'"
    
    # event taggings
    execute "UPDATE taggings,pages SET taggings.taggable_id = pages.id WHERE taggings.taggable_id = pages.migrated_id AND taggings.taggable_type = 'Event' and pages.datatype = 'Event'"

    # change all taggable_types to 'Page'
    execute "UPDATE taggings SET taggable_type = 'Page' WHERE taggable_type IN ('Article','Faq','Event')"
    add_index "taggings", ["tag_id", "taggable_id", "taggable_type", "tagging_kind", "owner_id"], :name => "taggingindex", :unique => true
    
    # bucketings
    remove_column(:bucketings, :bucketable_type)
    rename_column(:bucketings, :bucketable_id, :page_id)
    
    # linkings
    remove_column(:linkings, :contentitem_type)
    rename_column(:linkings, :contentitem_id, :page_id)
    
    # content_link_stat
    rename_column(:content_link_stats, :content_id, :page_id)
    
    # content_links
    remove_column(:content_links, :content_type)
    rename_column(:content_links, :content_id,   :page_id)
    rename_column(:content_links, :original_url, :url)
    rename_column(:content_links, :original_fingerprint, :fingerprint)
    
    # rename the table
    rename_table(:content_links, :links)
    rename_table(:content_link_stats, :link_stats)
    
    rename_column(:linkings, :content_link_id, :link_id)
    
    
    
  end

  def self.down
    drop_table(:pages)
  end
end
