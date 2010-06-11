class AddUploadToWidgets < ActiveRecord::Migration
  def self.up
    add_column :widgets, :upload_capable, :boolean, :default => false
  end

  def self.down
    remove_column :widgets, :upload_capable
  end
end
