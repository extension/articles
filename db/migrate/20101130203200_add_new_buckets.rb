class AddNewBuckets < ActiveRecord::Migration
  def self.up
    originalnews = ContentBucket.create(:name => 'originalnews')
    notnews = ContentBucket.create(:name => 'notnews')
    news_tag = Tag.find_by_name('news')
    
    # populate the notnews bucketings
    execute "INSERT INTO bucketings (bucketable_id,bucketable_type,content_bucket_id,created_at,updated_at) SELECT articles.id,'Article',#{notnews.id},NOW(),NOW() from articles where articles.id NOT IN (SELECT articles.id FROM `articles` INNER JOIN `taggings` ON `articles`.id = `taggings`.taggable_id AND `taggings`.taggable_type = 'Article' WHERE ((`taggings`.tag_id = #{news_tag.id})))"
    
  end

  def self.down
  end
end
