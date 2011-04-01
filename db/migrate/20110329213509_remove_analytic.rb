class RemoveAnalytic < ActiveRecord::Migration
  def self.up
    drop_table(:analytics)
  end

  def self.down
  end
end
