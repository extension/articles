class AddSponsorshipLevel < ActiveRecord::Migration
  def self.up
   add_column :sponsors, :level, :string
  end

  def self.down
   remove_column :sponsors, :level
  end
end
