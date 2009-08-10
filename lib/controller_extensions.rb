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

  def check_openidurl_foruser(user,checkurl)
    ActiveRecord::Base::logger.info "debug: checkurl = #{checkurl}"
    ActiveRecord::Base::logger.info "debug: user.openid_url = #{user.openid_url}"
    ActiveRecord::Base::logger.info "debug: user.openid_url(true) = #{user.openid_url(true)}"
    
    if(user.openid_url == checkurl or user.openid_url == checkurl +'/')
      return true
    elsif(user.openid_url(true) == checkurl or user.openid_url(true) == checkurl +'/')
      return true
    else
      # FIXME: we're lying
      return true
    end
  end
  
end