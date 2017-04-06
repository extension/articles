class AddCreateNodeId < ActiveRecord::Migration
  def up
    add_column(:pages, :create_node_id, :integer, :nil => true)
    Page.reset_column_information
    Page.where(source: 'create').all.each do |p|
      p.set_create_node_id
    end
  end

  def down
    remove_column(:pages, :create_node_id)
  end

end
