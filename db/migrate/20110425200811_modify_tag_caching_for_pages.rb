class ModifyTagCachingForPages < ActiveRecord::Migration
  def self.up
    add_column(:pages, :cached_content_tags, :text)
    execute "UPDATE pages,cached_tags SET pages.cached_content_tags = cached_tags.fulltextlist WHERE cached_tags.tagcacheable_id = pages.id and cached_tags.tagcacheable_type = 'Page'"
  end

  def self.down
    remove_column(:pages,:cached_content_tags)
  end
end
