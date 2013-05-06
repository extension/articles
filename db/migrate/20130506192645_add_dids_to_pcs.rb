class AddDidsToPcs < ActiveRecord::Migration
  def self.up
    add_column(:publishing_communities, 'drupal_node_id', :integer)
    execute("UPDATE publishing_communities,communities SET publishing_communities.drupal_node_id = communities.drupal_node_id WHERE publishing_communities.id = communities.id")

  end

  def self.down
  end
end
