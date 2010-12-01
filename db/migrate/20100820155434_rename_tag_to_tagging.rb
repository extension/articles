class RenameTagToTagging < ActiveRecord::Migration
  def self.up
    rename_column(:taggings, :tag_kind, :tagging_kind)
  end

  def self.down
  end
end
