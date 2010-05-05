class WidgetCustomFromEmail < ActiveRecord::Migration
  def self.up
    add_column :widgets, :email_from, :string, :null => true
  end

  def self.down
    remove_column :widgets, :email_from
  end
end
