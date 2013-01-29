class DropHelpFeed < ActiveRecord::Migration
  def self.up
    drop_table "help_feeds"
  end

  def self.down
  end
end
