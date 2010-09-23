class GoogleGroupDataEntry < ActiveRecord::Migration
  def self.up
    # add entries for extensionstaff and engineering since those are created
    Community.reset_column_information
    GoogleGroup.reset_column_information
    extensionstaff = Community.find_by_shortname('extensionstaff')    
    extensionstaff.update_attribute(:connect_to_google_apps, true)
    extensionstaff.google_group.touch(:apps_updated_at)

    engineering = Community.find_by_shortname('engineering')    
    engineering.update_attribute(:connect_to_google_apps, true)
    engineering.google_group.touch(:apps_updated_at)
  end

  def self.down
  end
end
