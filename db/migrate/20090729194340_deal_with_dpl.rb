class DealWithDpl < ActiveRecord::Migration
  def self.up
    add_column(:articles, :is_dpl, :boolean, :default => false)
    
    # flag the dpl articles so we efficiently throw them out of feed results
    execute "UPDATE articles,article_buckets,content_buckets SET articles.is_dpl = TRUE WHERE \
    articles.id = article_buckets.article_id and article_buckets.content_bucket_id = content_buckets.id and content_buckets.name = 'dpl'"
    
  end

  def self.down
  end
end
