class WidgetUrlRename < ActiveRecord::Migration
  def self.up
    rename_column(:widgets, :widget_url, :widgeturl)
  end

  def self.down
  end
end
