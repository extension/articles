# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'gappsprovisioning/provisioningapi'
include GAppsProvisioning

class GoogleGroup < ActiveRecord::Base
  attr_accessor :apps_connection
  serialize :last_error
  
  belongs_to :community

  before_save  :set_values_from_community

  GDATA_ERROR_ENTRYDOESNOTEXIST = 1301

  named_scope :needs_apps_update, {:conditions => "updated_at > apps_updated_at"}
  named_scope :no_apps_error, {:conditions => "has_error = 0"}
  named_scope :null_apps_update, {:conditions => "apps_updated_at IS NULL"}

  def set_values_from_community
    self.group_id = self.community.shortname
    self.group_name = self.community.name
    self.email_permission = 'Anyone'
    return true
  end
  
  def update_apps_group
    self.establish_apps_connection
    
    # check for a group - a little different than the google
    # account check - there's no single group retrieval, so
    # we'll just check for the apps_updated_at timestamp
    
    # create the group if it didn't exist
    if(self.apps_updated_at.blank?)
      begin
        google_group = self.apps_connection.create_group(self.group_id,[self.group_name,self.group_name,self.email_permission])
      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    else    
      # update the group
      begin
        google_group = self.apps_connection.update_group(self.group_id,[self.group_name,self.group_name,self.email_permission])

      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    end
    
    self.touch(:apps_updated_at)  
    # if we made it here, it must have worked
    return google_group
  end
  
  def update_apps_group_members
    # update the group for good measure
    
    if(!(google_group = self.update_apps_group))
      return nil
    else
      # get the members @google
      begin
        apps_group_members = self.apps_connection.retrieve_all_members(self.group_id).map(&:member_id)
      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
      
      # map the community members to an array of "blah@extension.org"
      community_members = self.community.joined.map{|u| "#{u.login}@extension.org"}
      
      adds = community_members - apps_group_members
      removes = apps_group_members - community_members
      
      # add the adds/remove the removes
      begin
        adds.each do |member_id|
          member = self.apps_connection.add_member_to_group(member_id, self.group_id)
        end
        
        removes.each do |member_id|
          member = self.apps_connection.remove_member_from_group(member_id, self.group_id)
        end
      rescue
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
      
      return google_group
    end
  end
      
    
  
  def establish_apps_connection(force_reconnect = false)
    if(self.apps_connection.nil? or force_reconnect)
      self.apps_connection = ProvisioningApi.new(AppConfig.configtable['googleapps_account'],AppConfig.configtable['googleapps_secret'])
    end
  end
  
  def self.retrieve_all_groups
    class_apps_connection = ProvisioningApi.new(AppConfig.configtable['googleapps_account'],AppConfig.configtable['googleapps_secret'])
    class_apps_connection.retrieve_all_groups
  end
  
  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
    
end