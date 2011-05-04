class ChangeIndexing < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `pages` CHANGE COLUMN `indexed` `indexed` INT(11) NULL DEFAULT 1;"
  end

  def self.down
  end
end
