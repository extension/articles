class DumpListTables < ActiveRecord::Migration
  def self.up
    drop_table(:list_owners)
    drop_table(:list_subscriptions)
    drop_table(:list_posts)
    remove_column(:lists,:dropunconnected)
    remove_column(:lists,:dropforeignsubscriptions)
  end

  def self.down
  end
end
