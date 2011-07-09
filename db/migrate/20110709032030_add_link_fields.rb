class AddLinkFields < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE `links` ADD COLUMN `alias_fingerprint` VARCHAR(255) NULL DEFAULT NULL  AFTER `url`;"
    execute "ALTER TABLE `links` ADD COLUMN `alias_url` TEXT NULL DEFAULT NULL  AFTER `alias_fingerprint`;"
    add_index "links", ["alias_fingerprint"], :name => "alias_fingerprint_ndx"
  end

  def self.down
  end
end
