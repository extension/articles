# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


module ControllerExtensions

  def additionaldata_from_params(params)
    additionaldata = params
    additionaldata[:remoteaddr] = request.env["REMOTE_ADDR"]
    additionaldata[:password] = '[FILTERED]' if(!additionaldata[:password].nil?)
    additionaldata[:user_password] = '[FILTERED]' if(!additionaldata[:user_password].nil?)
    additionaldata[:password_confirmation] = '[FILTERED]' if(!additionaldata[:password_confirmation].nil?)
    additionaldata[:login] = params[:user_login] if(!additionaldata[:user_login].nil?)
    return additionaldata
  end

  def log_user_activity(opts = {})
    # creator check
    if(opts[:creator].nil?)
      @currentuser.nil? ? opts[:creator] = opts[:user] : opts[:creator] = @currentuser
    end
    Activity.log_activity(opts)
  end

  def log_admin_event(user, event, data = nil)
    AdminEvent.log_event(user, event, request.env["REMOTE_ADDR"], data)
  end
  
  def openidurl
    proto = request.ssl? ? 'https://' : 'http://'
    url_for(:controller => 'opie', :action => 'user', :extensionid => @currentuser.login.downcase, :protocol => proto)
  end
  
  def check_openidurl_foruser(user,checkurl)
    proto = request.ssl? ? 'https://' : 'http://'
    allowedurls = Array.new
    
    allowedurls << url_for(:controller => 'opie', :action => 'user', :extensionid => user.login.downcase, :protocol => proto)
    # trailing slash
    allowedurls << url_for(:controller => 'opie', :action => 'user', :extensionid => user.login.downcase, :protocol => proto)+'/'

    # old style 
    allowedurls << url_for(:controller => 'openid', :action => user.login.downcase, :protocol => proto)
    allowedurls << url_for(:controller => 'openid', :action => user.login.downcase, :protocol => proto)+'/'
    
    return allowedurls.include?(checkurl)
  end
    
  def openidurlforuser(user)
    proto = request.ssl? ? 'https://' : 'http://'
    url_for(:controller => 'opie', :action => 'user', :extensionid => user.login.downcase, :protocol => proto)
  end
  
end