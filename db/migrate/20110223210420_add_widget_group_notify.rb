class AddWidgetGroupNotify < ActiveRecord::Migration
  def self.up
    add_column :widgets, :group_notify, :boolean, :default => false
  end

  def self.down
  end
end
