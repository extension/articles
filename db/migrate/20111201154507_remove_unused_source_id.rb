class RemoveUnusedSourceId < ActiveRecord::Migration
  def self.up
    remove_column("pages", 'source_id')    
  end

  def self.down
  end
end
