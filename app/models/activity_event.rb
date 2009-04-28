# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ActivityEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :activity_application
  validates_presence_of :user, :event
  serialize :eventdata
  
  # feed related events
  FEEDREQUEST = 100
  INVALIDFEEDREQUEST = 101
  
  # system events
  RETRIEVE_DATA_SUCCESS = 1001
  RETRIEVE_DATA_FAILURE = 1002

  
  
  DESCRIPTIONS = {FEEDREQUEST => {:description => 'Requested a feed'},
           INVALIDFEEDREQUEST => {:description => 'Invalid feed request'},
           RETRIEVE_DATA_SUCCESS => {:description => 'Successfully retrieved data'},
           RETRIEVE_DATA_FAILURE => {:description => 'Failed to retrieve data'}}

  
  def description
    ActivityEvent::DESCRIPTIONS.include?(self.event) ? ActivityEvent::DESCRIPTIONS[self.event][:description] : "Unknown"
  end
  
  # -----------------------------------
  # Class-level methods
  # -----------------------------------
  class << self
    
    def log_event(options)
      creationoptions = options
      if(creationoptions[:user].nil?)
        creationoptions[:user] = User.peoplebot
      end
    
      # ip address
      if(creationoptions[:ipaddr].nil?)
        creationoptions[:ipaddr] = AppConfig.configtable['request_ip_address']
      end
      self.create(creationoptions)
    end
  
    def log_system_event(options)
      creationoptions = options
      creationoptions[:user] = User.peoplebot # Mr. Peoplebot
      # ip address
      if(creationoptions[:ipaddr].nil?)
        creationoptions[:ipaddr] = AppConfig.configtable['request_ip_address']
      end
      self.create(creationoptions)
    end
  
  end
end