class AddTimezoneToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :time_zone, :string, :null => true
  end

  def self.down
  end
end
