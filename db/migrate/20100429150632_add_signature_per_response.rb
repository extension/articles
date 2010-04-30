class AddSignaturePerResponse < ActiveRecord::Migration
  def self.up
    add_column :responses, :signature, :text, :null => true
  end

  def self.down
    remove_column :responses, :signature
  end
end
