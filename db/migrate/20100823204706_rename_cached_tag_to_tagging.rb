class RenameCachedTagToTagging < ActiveRecord::Migration
  def self.up
    rename_column(:cached_tags, :tag_kind, :tagging_kind)
  end

  def self.down
  end
end
