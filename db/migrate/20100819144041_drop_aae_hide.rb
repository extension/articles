class DropAaeHide < ActiveRecord::Migration
  def self.up
    remove_column(:communities, 'hide_from_aae')    
  end

  def self.down
  end
end
