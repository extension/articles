class AddAlternateLinkFields < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `links` ADD COLUMN `alternate_fingerprint` VARCHAR(255) NULL DEFAULT NULL  AFTER `alias_url`;"
    execute "ALTER TABLE `links` ADD COLUMN `alternate_url` TEXT NULL DEFAULT NULL  AFTER `alternate_fingerprint`;"
    add_index "links", ["alternate_fingerprint"], :name => "alternate_fingerprint_ndx"
  end

  def self.down
  end
end
