class DropAuthorStringFromWidgets < ActiveRecord::Migration
  def self.up
    remove_column(:widgets, :author)
  end

  def self.down
  end
end
