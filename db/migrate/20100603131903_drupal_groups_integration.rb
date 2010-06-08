class DrupalGroupsIntegration < ActiveRecord::Migration
  def self.up
    add_column(:communities, :connect_to_drupal, :boolean, :default => false)
    add_column(:communities, :drupal_node_id, :integer, :null => true)
    execute "UPDATE communities SET connect_to_drupal = 1 WHERE show_in_public_list = 1 AND entrytype IN(#{Community::APPROVED},#{Community::USERCONTRIBUTED})"
    # HorseQuest
    execute "UPDATE communities SET drupal_node_id = 6 WHERE id = 10"  
    # Consumer Horticulture
    execute "UPDATE communities SET drupal_node_id = 8 WHERE id = 2"  
    # Map@Syst
    execute "UPDATE communities SET drupal_node_id = 7 WHERE id = 14"  
  end

  def self.down
  end
end
