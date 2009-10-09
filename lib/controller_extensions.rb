# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


module ControllerExtensions

  def log_user_activity(opts = {})
    # creator check
    if(opts[:creator].nil?)
      @currentuser.nil? ? opts[:creator] = opts[:user] : opts[:creator] = @currentuser
    end
    Activity.log_activity(opts)
  end

  def check_openidurl_foruser(user,checkurl)
    if(user.openid_url == checkurl or user.openid_url == checkurl +'/')
      return true
    elsif(user.openid_url(true) == checkurl or user.openid_url(true) == checkurl +'/')
      return true
    else
      return false
    end
  end
  
end