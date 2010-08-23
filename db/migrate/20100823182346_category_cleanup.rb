class CategoryCleanup < ActiveRecord::Migration
  def self.up
    remove_column(:categories, :default_keyword)
    remove_column(:categories, :community_id)
    
    # convert all the names to lower case
    execute "UPDATE categories SET name = LOWER(name)"
  end

  def self.down
  end
end
