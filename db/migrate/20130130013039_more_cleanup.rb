class MoreCleanup < ActiveRecord::Migration
  def self.up
    drop_table "daily_numbers"
  end

  def self.down
  end
end
