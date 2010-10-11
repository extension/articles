class DropOldUsers < ActiveRecord::Migration
  def self.up
    drop_table('users')
    drop_table('public_users')
  end

  def self.down
  end
end
