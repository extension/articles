class DropMetaCommunityWork < ActiveRecord::Migration
  def self.up
    drop_table :metacommunityconnections
    remove_column :communities, :ismeta
    remove_column :communityconnections, :refcount
  end

  def self.down
  end
end
