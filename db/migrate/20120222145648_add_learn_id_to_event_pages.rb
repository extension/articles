class AddLearnIdToEventPages < ActiveRecord::Migration
  def self.up
    add_column :pages, :learn_id, :integer, :null => true
    add_index :pages, :learn_id
  end

  def self.down
    remove_column :pages, :learn_id
    remove_index :pages, :learn_id
  end
end
