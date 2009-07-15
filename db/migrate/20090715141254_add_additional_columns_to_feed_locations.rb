class AddAdditionalColumnsToFeedLocations < ActiveRecord::Migration
  def self.up
    add_column(:feed_locations, 'name', :string)
    add_column(:feed_locations, 'retrieve_with_time', :boolean, :default => false)
    
    # add name to eorganic feed
    execute "UPDATE `feed_locations` set name = 'eorganic.info' WHERE id=1"
  end

  def self.down
    remove_column(:feed_locations, 'name')
    remove_column(:feed_locations, 'retrieve_with_time')
  end
end
