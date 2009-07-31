class CorrectArticleCreateTime < ActiveRecord::Migration
  def self.up
    # mediawiki's atom feed has no <published> record, so the times for the article publication are always > updated time, which is a little crazy
    execute "UPDATE articles SET wiki_created_at = wiki_updated_at WHERE wiki_updated_at < wiki_created_at"
  end

  def self.down
  end
end
