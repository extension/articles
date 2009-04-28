# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class LoginEvent < ActiveRecord::Base
  belongs_to :user
  
  # logintypes
  LOCAL = 100
  API = 101
  OPENID = 102
   
    
  class << self

    def log(ltype, user, remoteip, appname)
      event = LoginEvent.new do |e|
        e.ltype = ltype
        if(user.nil?)
          e.user = nil
         else
          e.user = user
        end
        if(remoteip.nil?)
          e.remoteip = 'unknown'
        else
          e.remoteip = remoteip
        end
        e.appname = appname
      end
      event.save    
    end
    
    def translateappname(appname)
      
    end
    
  end
  
end