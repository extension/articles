class AddAaeAssigneeFlag < ActiveRecord::Migration
  def self.up
    add_column :users, :aae_responder, :boolean, :default => true
  end

  def self.down
    remove_column :users, :aae_responder
  end
end
