class ModifyFeatureTimestamps < ActiveRecord::Migration
  def self.up
    # force some of the feature articles to have an older timestamp when they were published
    execute "UPDATE articles SET wiki_updated_at = '2009-10-19 19:12:00' where title = 'Livestock and Poultry Environmental Learning Center Webcast Series'"
    execute "UPDATE articles SET wiki_updated_at = '2009-02-24 14:07:00' where title = 'Financial Security: Managing Money in Tough Times'"
    execute "UPDATE articles SET wiki_updated_at = '2009-10-07 16:15:00' where title = 'Livestock and Poultry Environmental Learning Center Newsletter'"
    execute "UPDATE articles SET wiki_updated_at = '2009-09-20 21:44:00' where title = 'Cooperative Extension Resources for Influenza A H1N1 (Swine Flu)'"
  end

  def self.down
  end
end
