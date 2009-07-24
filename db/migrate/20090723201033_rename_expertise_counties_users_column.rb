class RenameExpertiseCountiesUsersColumn < ActiveRecord::Migration
  def self.up
    rename_column :expertise_counties_users, :county_id, :expertise_county_id
  end

  def self.down
    rename_column :expertise_counties_users, :expertise_county_id, :county_id
  end
end
