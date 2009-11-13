class CleanupUserCommunityTags < ActiveRecord::Migration
  def self.up
    execute "DELETE FROM taggings where taggings.taggable_type = 'Community' and tag_kind = #{Tag::USER}"
  end

  def self.down
  end
end
