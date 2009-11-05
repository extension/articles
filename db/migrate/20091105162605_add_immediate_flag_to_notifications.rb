class AddImmediateFlagToNotifications < ActiveRecord::Migration
  def self.up
    add_column :notifications, :send_on_create, :boolean, :default => false
  end

  def self.down
  end
end
