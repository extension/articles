class AddSomeIndexes < ActiveRecord::Migration
  def self.up
    add_index("taggings", ["taggable_id","taggable_type","tagging_kind"])
  end

  def self.down
  end
end
