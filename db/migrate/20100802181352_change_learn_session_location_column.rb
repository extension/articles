class ChangeLearnSessionLocationColumn < ActiveRecord::Migration
  def self.up
    rename_column(:learn_sessions, :where, :location)
  end

  def self.down
  end
end
