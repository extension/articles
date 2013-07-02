class AddTwitterWidgetToCommunities < ActiveRecord::Migration
  def self.up
    add_column :publishing_communities, :twitter_widget, :text, :null => true
  end

  def self.down
    remove_column :publishing_communities, :twitter_widget
  end
end
