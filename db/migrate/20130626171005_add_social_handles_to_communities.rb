class AddSocialHandlesToCommunities < ActiveRecord::Migration
  def self.up
    add_column :publishing_communities, :facebook_handle, :string, :null => true
    add_column :publishing_communities, :twitter_handle, :string, :null => true
    add_column :publishing_communities, :youtube_handle, :string, :null => true
    add_column :publishing_communities, :pinterest_handle, :string, :null => true
    add_column :publishing_communities, :gplus_handle, :string, :null => true
  end

  def self.down
    remove_column :publishing_communities, :facebook_handle
    remove_column :publishing_communities, :twitter_handle
    remove_column :publishing_communities, :youtube_handle
    remove_column :publishing_communities, :pinterest_handle
    remove_column :publishing_communities, :gplus_handle
  end
end