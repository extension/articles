class DumpLearnTables < ActiveRecord::Migration
  def self.up
    drop_table "learn_connections"
    drop_table "learn_sessions"
  end

  def self.down
  end
end
