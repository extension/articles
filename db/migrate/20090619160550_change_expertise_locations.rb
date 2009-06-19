class ChangeExpertiseLocations < ActiveRecord::Migration
  
  ## change naming for expertise locations due to user's profiles referencing records from the same
  ## locations and counties tables to avoid active record and db confusion
  def self.up
    create_table :expertise_locations do |t|
      t.integer :fipsid, :entrytype, :null => false
      t.string :name, :null => false
      t.string :abbreviation, :limit => 10, :null => false
    end 
    
    # index on name
    add_index(:expertise_locations, :name, :unique => true)
    
    # dump existing data from locations table into new expertise_locations table
    execute("INSERT INTO expertise_locations SELECT * FROM locations")
    
    # rename the join table for the habtm relationship with users
    rename_table(:locations_users, :expertise_locations_users)
  
    ### Do the same for counties ###
    create_table :expertise_counties do |t|
      t.integer :fipsid, :location_id, :state_fipsid, :null => false
      t.string :countycode, :limit => 3, :null => false
      t.string :name, :null => false
      t.string :censusclass, :limit => 2, :null => false
    end
    
    # indices for name and location_id
    add_index(:expertise_counties, :name)
    add_index(:expertise_counties, :location_id)
    
    # dump existing counties from counties table into expertise_counties table
    execute("INSERT INTO expertise_counties SELECT * FROM counties")
    
    # rename the join table for the habtm relationship with users
    rename_table(:counties_users, :expertise_counties_users)
  end

  def self.down
    drop_table :expertise_locations
    drop_table :expertise_counties
    rename_table(:expertise_locations_users, :locations_users)
    rename_table(:expertise_counties_users, :counties_users)
  end
end
