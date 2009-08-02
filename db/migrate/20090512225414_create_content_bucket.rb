class CreateContentBucket < ActiveRecord::Migration
  def self.up
    # create a classifications architecture that we can bucket article types in - homage, news, etc.
    
    create_table "content_buckets", :force => true do |t|
      t.string   "name",       :null => false
      t.datetime "created_at", :null => false
    end

    add_index "content_buckets", ["name"], :unique => true
    
    create_table "bucketings", :force => true do |t|
      t.integer   "bucketable_id",       :null => false
      t.string   "bucketable_type",       :null => false
      t.integer   "content_bucket_id",       :null => false
      t.timestamps
    end
    
    add_index "bucketings", ["bucketable_id","bucketable_type","content_bucket_id"] ,:name => "bucketingindex", :unique => true
    
    bucketlist = ['contents', 'dpl', 'feature', 'homage', 'youth', 'learning lessons', 'news']
                  

    insert_time = Time.now.utc.to_s(:db)
    values_string = bucketlist.map{|name| "('#{name}','#{insert_time}')"}.join(',')
    execute "INSERT IGNORE INTO content_buckets (name,created_at) VALUES #{values_string}"
    
    # go through the bucketlist and insert a whole bunch of entries into the article_buckets table.
    bucketlist.each do|bucketname|
      # get the content bucket id 
      bucketid = ContentBucket.find_by_name(bucketname).id
      
      # find all the article id's that are tagged with this bucket
      taggings = Tagging.all(:include => :tag, :conditions => "tags.name = '#{bucketname}' and taggings.tag_kind = #{Tag::CONTENT} and taggable_type = 'Article'")
      bucket_records = []
      article_ids = taggings.map(&:taggable_id)
      article_ids.each do |aid|
        bucket_records << "(#{aid},'Article',#{bucketid},'#{insert_time}','#{insert_time}')"
      end
      
      # go through taggings_to_insert, 500 at a time
      say_with_time "Bulk inserting article buckets: #{bucketname}..." do
        while (insert_chunk = bucket_records.slice!(0,500) and !insert_chunk.empty?)
          insert_sql = "INSERT IGNORE INTO bucketings (bucketable_id,bucketable_type,content_bucket_id,created_at,updated_at) VALUES #{insert_chunk.join(',')}"
          suppress_messages {execute insert_sql}
        end
      end      
    end
        
  end

  def self.down
  end
end
