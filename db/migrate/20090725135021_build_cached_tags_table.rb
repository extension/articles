class BuildCachedTagsTable < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `cached_tags`  ENGINE = MYISAM"
    
    # build cached tags table for Communities - which is the only cached really at the moment
    CachedTag.rebuild_all(Community)
    
  end

  def self.down
  end
end
