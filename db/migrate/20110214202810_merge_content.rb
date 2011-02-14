class MergeContent < ActiveRecord::Migration
  def self.up
    create_table "pages", :force => true do |t|
      t.string   "datatype"
      t.text     "title"
      t.text     "content",          :limit => 16777215
      t.text     "original_content", :limit => 16777215
      t.datetime "source_published_at"
      t.datetime "source_updated_at"
      t.text   "source_url"
      t.boolean  "is_dpl",                               :default => false
      t.text     "reference_pages"
      t.integer  "migrated_id"
      t.boolean  "has_broken_links"
      t.text     "coverage"
      t.text     "state_abbreviations"
      t.date     "event_date"
      t.time     "event_time"
      t.datetime "event_start"
      t.string   "event_time_zone"
      t.text     "event_location"
      t.integer  "event_duration"
      t.datetime "created_at"
      t.datetime "updated_at"  
    end

    add_index "pages", ["datatype","migrated_id"] 
    add_index "pages", ["title"], :length => {"title"=>"255"}
    add_index "pages", ["source_published_at", "source_updated_at"]
    add_index "pages", ["event_date"]
    
    # articles        
    article_query = "INSERT INTO pages (id,datatype,title,content,original_content,source_published_at,source_updated_at,source_url,is_dpl,has_broken_links,created_at,updated_at)"
    article_query += " SELECT id,'Article',title,content,original_content,wiki_created_at,wiki_updated_at,original_url,is_dpl,has_broken_links,created_at,updated_at  FROM articles"
    execute article_query
    
    # faqs
    faq_query = "INSERT INTO pages (datatype,title,content,original_content,source_published_at,source_updated_at,source_url,reference_pages,migrated_id,created_at,updated_at)"
    faq_query += " SELECT 'Faq',question,answer,answer,heureka_published_at,heureka_published_at,CONCAT('http://cop.extension.org/publish/show/',id),reference_questions,id,created_at,updated_at FROM faqs"
    execute faq_query

    # events
    event_query = "INSERT INTO pages (datatype,title,content,original_content,source_published_at,source_updated_at,source_url,migrated_id,created_at,updated_at,coverage,state_abbreviations,event_date,event_time,event_start,event_time_zone,event_location,event_duration)"
    event_query += " SELECT 'Event',title,description,description,xcal_updated_at,xcal_updated_at,CONCAT('http://cop.extension.org/events/',id),id,created_at,updated_at,coverage,state_abbreviations,date,time,start,time_zone,location,duration FROM events"
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
    
  end

  def self.down
    drop_table(:pages)
  end
end
