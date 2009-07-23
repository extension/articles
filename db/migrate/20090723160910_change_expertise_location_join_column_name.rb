class ChangeExpertiseLocationJoinColumnName < ActiveRecord::Migration
  def self.up
    rename_column :expertise_locations_users, :location_id, :expertise_location_id
  end

  def self.down
    rename_column :expertise_locations_users, :expertise_location_id, :location_id
  end
end
