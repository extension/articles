class CreatePageSources < ActiveRecord::Migration
  def self.up
    add_column(:pages, 'page_source_id', :integer)
    
    create_table "page_sources", :force => true do |t|
      t.string   "name"
      t.string   "uri",                :null => false
      t.string   "page_uri"           
      t.string   "page_uri_column"    
      t.string   "demo_uri"
      t.string   "demo_page_uri"
      t.boolean  "active",             :default => true
      t.boolean  "retrieve_with_time", :default => true
      t.text     "default_request_options"
      t.datetime "latest_source_time"
      t.datetime "last_requested_at"
      t.boolean  "last_requested_success"
      t.text     "last_requested_information"
      t.timestamps
    end
    
    # create default sources
    PageSource.reset_column_information
    
    # copwiki
    PageSource.create(:name => 'copwiki', 
                      :uri => 'http://cop.extension.org/wiki/Special:Feeds', 
                      :page_uri => 'http://cop.extension.org/wiki/Special:Feeds/%s', 
                      :page_uri_column => 'title',
                      :demo_uri => 'http://cop.demo.extension.org/wiki/Special:Feeds',
                      :demo_page_uri => 'http://cop.demo.extension.org/wiki/Special:Feeds/%s',
                      :default_request_options => {'unpublished' => 1, 'published' => 1, 'dpls' => 1})
                      
    # faq
    PageSource.create(:name => 'copfaq', :uri => 'http://cop.extension.org/feeds/faqs', :demo_uri => 'http://cop.demo.extension.org/feeds/faqs')
    
    # events
    PageSource.create(:name => 'copevents', :uri => 'http://cop.extension.org/feeds/events',:demo_uri => 'http://cop.demo.extension.org/feeds/events')
    
    # eorganic
    PageSource.create(:name => 'eorganic', :uri => 'http://eorganic.info/extension/feed',:retrieve_with_time => false)
    
    # pbgworks
    PageSource.create(:name => 'pbgworks', :uri => 'http://pbgworks.org/extension/feed',:retrieve_with_time => false)
    
    # create?
    # TODO
    
    # transfer over update times.
    execute "UPDATE page_sources,update_times SET page_sources.latest_source_time = update_times.last_datasourced_at WHERE page_sources.name = 'copwiki' AND update_times.datasource_type = 'Article' and update_times.datatype = 'content'"
    execute "UPDATE page_sources,update_times SET page_sources.latest_source_time = update_times.last_datasourced_at WHERE page_sources.name = 'copfaq' AND update_times.datasource_type = 'Faq' and update_times.datatype = 'content'"
    execute "UPDATE page_sources,update_times SET page_sources.latest_source_time = update_times.last_datasourced_at WHERE page_sources.name = 'copevents' AND update_times.datasource_type = 'Event' and update_times.datatype = 'content'"
    execute "UPDATE page_sources,update_times SET page_sources.latest_source_time = update_times.last_datasourced_at WHERE page_sources.name = 'eorganic' AND update_times.datasource_id = 1 AND update_times.datasource_type = 'FeedLocation' and update_times.datatype = 'articles'"
    execute "UPDATE page_sources,update_times SET page_sources.latest_source_time = update_times.last_datasourced_at WHERE page_sources.name = 'pbgworks' AND update_times.datasource_id = 2 AND update_times.datasource_type = 'FeedLocation' and update_times.datatype = 'articles'"
  end

  def self.down
    remove_column(:pages, :page_source_id)
    drop_table(:page_sources)
  end
end
