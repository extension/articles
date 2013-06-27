class DropCachedTagTable < ActiveRecord::Migration
  def self.up
    drop_table "cached_tags"
  end

end
