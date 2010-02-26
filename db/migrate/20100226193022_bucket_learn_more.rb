class BucketLearnMore < ActiveRecord::Migration
  def self.up
    insert_time = Time.now.utc.to_s(:db)
    execute "INSERT IGNORE INTO content_buckets (name,created_at) VALUES ('learn more','#{insert_time}')"
    
    bucketid = ContentBucket.find_by_name('learn more').id
      
    # find all the article id's that are tagged with this bucket
    taggings = Tagging.all(:include => :tag, :conditions => "tags.name = 'learn more' and taggings.tag_kind = #{Tagging::CONTENT} and taggable_type = 'Article'")
    bucket_records = []
    article_ids = taggings.map(&:taggable_id)
    article_ids.each do |aid|
      bucket_records << "(#{aid},'Article',#{bucketid},'#{insert_time}','#{insert_time}')"
    end
      
    # go through taggings_to_insert, 500 at a time
    say_with_time "Bulk inserting article buckets: 'learn_more'..." do
      while (insert_chunk = bucket_records.slice!(0,500) and !insert_chunk.empty?)
        insert_sql = "INSERT IGNORE INTO bucketings (bucketable_id,bucketable_type,content_bucket_id,created_at,updated_at) VALUES #{insert_chunk.join(',')}"
        suppress_messages {execute insert_sql}
      end
    end   
  end

  def self.down
  end
end
