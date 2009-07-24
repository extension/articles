class ChangeExpertiseCountyColumnName < ActiveRecord::Migration
  def self.up
    rename_column :expertise_counties, :location_id, :expertise_location_id
  end

  def self.down
    rename_column :expertise_counties, :expertise_location_id, :location_id
  end
end
