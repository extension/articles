class AddWidgetActivation < ActiveRecord::Migration
  def self.up
    add_column :widgets, :active, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :widgets, :active
  end
end
