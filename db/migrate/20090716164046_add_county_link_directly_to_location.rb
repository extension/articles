class AddCountyLinkDirectlyToLocation < ActiveRecord::Migration
  def self.up
    add_column(:locations, :office_link, :string)
    execute "UPDATE locations, county_links SET locations.office_link = county_links.office_link WHERE county_links.location_id = locations.id"
    drop_table(:county_links)
  end

  def self.down
    # not reversible
  end
end
