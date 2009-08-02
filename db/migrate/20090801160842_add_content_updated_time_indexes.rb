class AddContentUpdatedTimeIndexes < ActiveRecord::Migration
  def self.up
    add_index("articles", ["wiki_created_at","wiki_updated_at"])
    add_index("faqs", ["heureka_published_at"])
    add_index("events", ["xcal_updated_at"])
    add_index("events", ["date"])
  end

  def self.down
  end
end
