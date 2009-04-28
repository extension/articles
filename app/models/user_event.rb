# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class UserEvent < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :etype, :ip
  serialize :additionaldata

  # types 
  MISC = 1
  STATUSCHANGE = 2
  PROFILE = 3
  AGREEMENT = 4
  OPENID = 5
  INVITATION = 6
  COMMUNITY = 7
  
  #
  FEEDREQUEST = 100
  INVALIDFEEDREQUEST = 101
  
  # login events
  
  LOGIN_API_SUCCESS = 200
  LOGIN_OPENID_SUCCESS = 201
  LOGIN_LOCAL_SUCCESS = 202
  
  LOGIN_API_FAILED = 300
  LOGIN_OPENID_FAILED = 301
  LOGIN_LOCAL_FAILED = 302 
  
  
  # peoplebot events
  RETRIEVE_DATA_SUCCESS = 1001
  RETRIEVE_DATA_FAILURE = 1002
  
  def self.log_peoplebot_event(opts)
    opts[:user] = user = User.find(1) # Mr. Peoplebot
    opts[:login] = user.login
    opts[:ip] = 'local'
    UserEvent.create(opts)
  end

  
  def self.log_event(opts = {})    
    # user and login convenience column
    if(opts[:user].nil?)
      opts[:login] = opts[:additionaldata][:login].nil? ? 'unknown' : opts[:additionaldata][:login]
    else
      opts[:login] = opts[:user].login
    end

    # ip address
    if(opts[:ip].nil?)
      opts[:ip] = AppConfig.configtable['request_ip_address']
    end

    # appname
    opts[:appname] = 'local' if(opts[:appname].nil?)
    
    UserEvent.create(opts)
  end 

  def self.per_page
    50
  end
end

