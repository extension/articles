require_dependency "user"

module LoginSystem 
  
  protected
  

  
  # overwrite this if you want to restrict access to only a few actions
  # or if you want to check if the user has the correct rights  
  def authorize?(checkuser)
    if not checkuser
      return false
    elsif checkuser.retired?
      return false
    elsif AppConfig.configtable['reserved_uids'].include?(checkuser.id)
      return false
    elsif checkuser.last_login_at < Time.now.utc - 2.days
      return false
    else
      return true
    end
  end
    
  def sudoer?(checkuser)
    (authorize?(checkuser) && AppConfig.configtable['sudoers'][checkuser.login.downcase]) 
  end
  
  def purgatory?(checkuser)
    if(!checkuser.vouched?)
      return true
    else # status checks
      case checkuser.account_status
      when User::STATUS_CONTRIBUTOR
        return false
      when User::STATUS_PARTICIPANT
        return false
      when User::STATUS_REVIEWAGREEMENT
        return false
      else
        return true
      end
    end
  end
  

  
  # login_required filter. add 
  #
  #   before_filter :login_required
  #
  # if the controller should be under any rights management. 
  # for finer access control you can overwrite
  #   
  #   def authorize?(user)
  #
  def check_purgatory
    if !purgatory?(@currentuser)
      return true
    else
      clear_location
      access_notice
      return false
    end
  end
  
  # this is a bit of a hack in order to get global
  # timezones in situations where login_required/login_optional
  # hasn't yet been executed
  def set_currentuser_time_zone
    if session[:userid]      
      checkuser = User.find_by_id(session[:userid])
      if (authorize?(checkuser))
        Time.zone = checkuser.time_zone
        return true
      end
    end
  end
  
  def login_required    

    if session[:userid]      
      checkuser = User.find_by_id(session[:userid])
      if (authorize?(checkuser))
        @currentuser = checkuser
        return true
      end
    end

    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied
    return false 
  end
  
  def login_optional
    if session[:userid]      
      checkuser = User.find_by_id(session[:userid])
      if (authorize?(checkuser))
        @currentuser = checkuser
        return true
      end
    end
    
    return false
  end
    
  def admin_required

     if session[:userid]
        checkuser = User.find_by_id(session[:userid])
        if (checkuser.is_admin)
          @currentuser = checkuser
          return true
        end
     end

    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied
    return false
  end
  

  

  def sudo_required
     if session[:userid]
        checkuser = User.find_by_id(session[:userid])
        if (sudoer?(checkuser))
          @currentuser = checkuser
          return true
        end
     end

    # store current location so that we can 
    # come back after the user logged in
    store_location
  
    # call overwriteable reaction to unauthorized access
    access_denied
    return false
  end
  
  # overwrite if you want to have special behavior in case the user is not authorized
  # to access the current operation. 
  # the default action is to redirect to the login screen
  # example use :
  # a popup window might just close itself for instance
  def access_denied
    redirect_to login_url
  end  
  
  def access_notice
    redirect_to people_notice_url
  end
  
  # store current uri in  the session.
  # we can return to this location by calling return_location
  def store_location
    ActiveRecord::Base::logger.info "login: storing return_to = #{request.request_uri}"
    session[:return_to] = request.request_uri
  end
  
  def clear_location
    session[:return_to] = nil
  end

  # move to the last store_location call or to the passed default one
  def redirect_back_or_default(default)
    if session[:return_to].nil?
      redirect_to default
    else
      # add a debugging statement here so that we can get a feel for the current login errors
      ActiveRecord::Base::logger.info "login: redirecting to #{session[:return_to]}"
      redirect_to session[:return_to]
      session[:return_to] = nil
    end
  end
  
  def openid_xrds_header
    proto = request.ssl? ? 'https://' : 'http://'
    response.headers['X-XRDS-Location'] = url_for(:controller => '/opie', :action => :idp_xrds, :protocol => 'https://')
    xrds_url = url_for(:controller=>'/opie', :action=> 'idp_xrds', :protocol => 'https://')
    return xrds_url
  end
  
  def openidmeta(openiduser=nil)
    returnstring = '<link rel="openid.server" href="'+AppConfig.openid_endpoint+'" />'
    returnstring += '<link rel="openid2.provider openid.server" href="'+AppConfig.openid_endpoint+'" />'
    if(!openiduser.nil?)
      returnstring += '<link rel="openid2.local_id openid.delegate" href="'+openiduser.openid_url+'" />'
    else
      xrds_url = openid_xrds_header
      returnstring += '<meta http-equiv="X-XRDS-Location" content="'+xrds_url+'" />'+"\n"
    end
    return returnstring
  end

end