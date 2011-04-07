class DumpListTables < ActiveRecord::Migration
  def self.up
    drop_table(:list_owners)
    drop_table(:list_subscriptions)
    drop_table(:list_posts)
    remove_column(:lists,:dropunconnected)
    remove_column(:lists,:dropforeignsubscriptions)
    add_column(:lists,:community_id,:integer)
    add_column(:lists,:connectiontype,:string)
    execute "UPDATE lists,communitylistconnections SET lists.community_id = communitylistconnections.community_id,lists.connectiontype = communitylistconnections.connectiontype WHERE communitylistconnections.list_id = lists.id"
    drop_table(:communitylistconnections)
  end

  def self.down
  end
end
