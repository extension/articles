# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AdminLog < ActiveRecord::Base
  serialize :data

  belongs_to :person

  DELETE_TOPIC = 50
  CREATE_TOPIC = 51
  UPDATE_LOCATION_OFFICE_LINK = 52
  UPDATE_PUBLIC_COMMUNITY = 53
  UPDATE_PUBLIC_INSTITUTION = 54
  DELETE_FEED_LOCATION = 55
  CREATE_FEED_LOCATION = 56
  UPDATE_FEED_LOCATION = 57
  DELETE_LOGO = 58
  CREATE_LOGO = 59
  DELETE_SPONSOR = 60
  CREATE_SPONSOR = 61
  UPDATE_SPONSOR = 62
  REORDER_SPONSORS = 63
  UPDATE_PUBLIC_CATEGORY = 64


  DESCRIPTIONS =  {DELETE_TOPIC => {:description => 'Deleted Topic'},
                   CREATE_TOPIC => {:description => 'Created Topic'},
                   UPDATE_LOCATION_OFFICE_LINK => {:description => 'Updated Office Link for Location'},
                   UPDATE_PUBLIC_COMMUNITY => {:description => 'Updated Public Attributes for Community'},
                   UPDATE_PUBLIC_INSTITUTION => {:description => 'Updated Public Attributes for Institution'},
                   DELETE_FEED_LOCATION => {:description => 'Deleted Feed Location'},
                   CREATE_FEED_LOCATION => {:description => 'Created Feed Location'},
                   UPDATE_FEED_LOCATION => {:description => 'Updated Feed Location'},
                   DELETE_LOGO => {:description => 'Deleted Logo'},
                   CREATE_LOGO => {:description => 'Created Logo'},
                   DELETE_SPONSOR => {:description => 'Deleted Sponsor'},
                   CREATE_SPONSOR => {:description => 'Created Sponsor'},
                   UPDATE_SPONSOR => {:description => 'Updated Sponsor'},
                   REORDER_SPONSORS => {:description => 'Reordered Sponsors'},
                   UPDATE_PUBLIC_CATEGORY => {:description => 'Updated public setting for category'}}

  
  def description
    DESCRIPTIONS.include?(self.event) ? DESCRIPTIONS[self.event][:description] : "Unknown"
  end
  
  def self.log_event(person, event, data = nil)
    newae = self.new do |ae|
      ae.person = person
      ae.event = event
      ae.ip = Settings.request_ip_address
      ae.data = data
    end
    newae.save
  end
end