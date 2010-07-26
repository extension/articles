# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AdminEvent < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :user, :event
  serialize :data
  
  REVOKEAGREEMENT = 1
  REVOKEAGREEMENT_REQUEST = 2
  ENABLE_ACCOUNT  = 3
  RETIRE_ACCOUNT  = 4
  DELETE_API_KEY  = 5 # no longer used
  ADD_API_KEY  = 6 # no longer used
  DELETE_ADMIN  = 7
  ADD_ADMIN  = 8
  ACCOUNT_INVALIDEMAIL  = 9
  CHANGE_EMAIL = 10
  
  
  # PUBSITE EVENTS
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
  
  # LIST EVENTS
  CREATE_LIST = 100
  CONNECT_LIST = 101
  UPDATE_SUBSCRIPTIONS = 102
  UPDATE_OWNERS = 103
  
  # USER LIST EVENTS
  CREATE_SUBSCRIPTION= 200
  UPDATE_SUBSCRIPTION = 201
  REMOVE_SUBSCRIPTION= 202
  REMOVE_OWNERSHIP = 203
  UPDATE_OWNERSHIP = 204
  CREATE_OWNERSHIP = 205
  
  
  # USER COMMUNITY EVENTS
  REMOVE_COMMUNITY_CONNECTION = 300
  
  # others
  SENT_NOTIFICATIONS = 400
  
  
  DESCRIPTIONS = {REVOKEAGREEMENT => {:description => 'Revoked Contributor Agreement'},
           REVOKEAGREEMENT_REQUEST => {:description => 'Made a Revoke Contributor Agreement Request'},
           ENABLE_ACCOUNT => {:description => 'Enabled an Account'},
           RETIRE_ACCOUNT => {:description => 'Retired an Account'},
           DELETE_API_KEY => {:description => 'Deleted an API Key'},
           ADD_API_KEY => {:description => 'Added an API Key'},
           DELETE_ADMIN => {:description => 'Removed Admin Status for User'},
           ADD_ADMIN => {:description => 'Added Admin Status for User'},
           ACCOUNT_INVALIDEMAIL => {:description => 'Marked an email invalid'},
           CHANGE_EMAIL => {:description => 'Changed an invalid email'},
           CREATE_LIST => {:description => 'Created a new mailing list'},
           CONNECT_LIST => {:description => 'Connected a community with a mailing list'},
           UPDATE_SUBSCRIPTIONS => {:description => 'Updated List Subscriptions'},
           UPDATE_SUBSCRIPTION => {:description => 'Updated a List Subscription'},
           CREATE_SUBSCRIPTION => {:description => 'Created List Subscription'},
           REMOVE_SUBSCRIPTION => {:description => 'Removed List Subscription'},
           REMOVE_OWNERSHIP => {:description => 'Removed List Ownership'},
           UPDATE_OWNERSHIP => {:description => 'Updated List Ownership'},
           CREATE_OWNERSHIP => {:description => 'Created List Ownership'},
           REMOVE_COMMUNITY_CONNECTION => {:description => 'Removed Community Connection'},
           UPDATE_OWNERS => {:description => 'Updated List Owners'},
           SENT_NOTIFICATIONS => {:description => 'Sent Notifications'},
           DELETE_TOPIC => {:description => 'Deleted Topic'},
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
    AdminEvent::DESCRIPTIONS.include?(self.event) ? AdminEvent::DESCRIPTIONS[self.event][:description] : "Unknown"
  end
  
  def self.log_event(user, event, data = nil)
    newae = AdminEvent.new do |ae|
      ae.user = user
      ae.event = event
      ae.ip = AppConfig.configtable['request_ip_address']
      ae.data = data
    end
    newae.save
  end
  
  def self.log_data_event(event_id, data, creator = nil)
    options = {:event => event_id, :data => data, :ip => AppConfig.configtable['request_ip_address']}
    if(creator.nil?)
      options[:user_id] = 1
    else
      options[:user_id] = creator.id
    end
    return AdminEvent.create(options)
  end
  
end