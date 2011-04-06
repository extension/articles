class CachedTagIndex < ActiveRecord::Migration
  def self.up
    add_index(:cached_tags, ["tagcacheable_id","tagcacheable_type","owner_id","tagging_kind"], :name => 'signature')
  end

  def self.down
  end
end
