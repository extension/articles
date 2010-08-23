class AddTimezoneToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :timezone, :string, :null => true
  end

  def self.down
  end
end
