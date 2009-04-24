class ConvertIdentityLocations < ActiveRecord::Migration
  def self.up
    execute "UPDATE `users`,`locations`,`identity_locations` SET `users`.`location_id` = `locations`.`id` WHERE `locations`.`abbreviation` = `identity_locations`.`abbreviation` AND `users`.`location_id` = `identity_locations`.`id`"
    execute "UPDATE `institutions`,`locations`,`identity_locations` SET `institutions`.`location_id` = `locations`.`id` WHERE `locations`.`abbreviation` = `identity_locations`.`abbreviation` AND `institutions`.`location_id` = `identity_locations`.`id`"
    drop_table :identity_locations
  end

  def self.down
    # uh. no.
  end
end
