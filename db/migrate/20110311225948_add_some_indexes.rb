class AddSomeIndexes < ActiveRecord::Migration
  def self.up
    add_index("tagginges", ["taggable_id","taggable_type","tagging_kind"])
  end

  def self.down
  end
end
