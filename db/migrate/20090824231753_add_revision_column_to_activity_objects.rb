class AddRevisionColumnToActivityObjects < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `activity_objects` ADD `foreignrevision` INT NULL AFTER `foreignid`"
  end

  def self.down
  end
end
