class ChangeLearnConnectiontype < ActiveRecord::Migration
  def self.up
    change_column :learn_connections, :connectiontype, :integer
  end

  def self.down
  end
end
