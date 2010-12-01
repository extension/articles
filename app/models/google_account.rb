# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
require 'gappsprovisioning/provisioningapi'
include GAppsProvisioning

class GoogleAccount < ActiveRecord::Base
  attr_accessor :apps_connection
  serialize :last_error
  
  belongs_to :user

  before_save  :set_values_from_user

  GDATA_ERROR_ENTRYDOESNOTEXIST = 1301

  named_scope :needs_apps_update, {:conditions => "updated_at > apps_updated_at"}
  named_scope :no_apps_error, {:conditions => "has_error = 0"}
  named_scope :null_apps_update, {:conditions => "apps_updated_at IS NULL"}


  def set_values_from_user
    self.user_id = self.user.id
    if(!self.no_sync_password?)
      self.password = self.user.password
    end
    self.username = self.user.login.downcase
    self.given_name = self.user.first_name
    self.family_name = self.user.last_name
    self.is_admin = self.user.is_admin?
    return true
  end
  
  def update_apps_account
    self.establish_apps_connection
    
    # check for an account
    begin
      google_account = self.apps_connection.retrieve_user(self.username)
    rescue GDataError => e
      if(e.code.to_i != GDATA_ERROR_ENTRYDOESNOTEXIST)
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    end
    
    # create the account if it didn't exist
    if(!google_account)
      begin
        google_account = self.apps_connection.create_user(self.username,self.given_name,self.family_name,self.password,"SHA-1")
      rescue GDataError => e
        self.update_attributes({:has_error => true, :last_error => e})
        return nil
      end
    end
    
    
    # update the account
    begin
      google_account = self.apps_connection.update_user(self.username,
                                                              self.given_name,
                                                              self.family_name,
                                                              self.password,"SHA-1",
                                                              self.is_admin? ? "true" : "false",
                                                              self.suspended? ? "true" : "false",
                                                              "false")
    rescue GDataError => e
      self.update_attributes({:has_error => true, :last_error => e})
      return nil
    end
    
    self.touch(:apps_updated_at)  
    # if we made it here, it must have worked
    return google_account
  end
  
  def establish_apps_connection(force_reconnect = false)
    if(self.apps_connection.nil? or force_reconnect)
      self.apps_connection = ProvisioningApi.new(AppConfig.configtable['googleapps_account'],AppConfig.configtable['googleapps_secret'])
    end
  end
  
  def self.retrieve_all_users
    class_apps_connection = ProvisioningApi.new(AppConfig.configtable['googleapps_account'],AppConfig.configtable['googleapps_secret'])
    class_apps_connection.retrieve_all_users
  end
  
  def self.clear_errors
    self.update_all("has_error = 0, last_error = ''","has_error = 1")
  end
end