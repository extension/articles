# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module AuthCheck
  AUTH_SUCCESS = 42
  
  AUTH_UNKNOWN = -1
  AUTH_INVALID_ID = 1
  AUTH_INVALID_PASSWORD = 2
  AUTH_EMAIL_NOTCONFIRM = 3
  AUTH_ACCOUNT_REVIEW = 4
  AUTH_INVALID_EMAIL  = 5
  AUTH_ACCOUNT_RETIRED = 6
  AUTH_INVALID_APIKEY = 7
  AUTH_ACCOUNT_NOTVOUCHED = 8
  AUTH_SIGNUP_CONFIRM = 9
  AUTH_PASSWORD_EXPIRED = 10

  
  def explainauthresult(resultcode)
    case resultcode
      when AUTH_INVALID_ID
        gourl = "<a href='"+url_for(:controller => '/people/signup', :action => :new)+"'>signup for an account</a>"
        explanation = "<p>The eXtensionID or email address was not found. Please check that ID/email again, or #{gourl}.</p>"        
      when AUTH_INVALID_PASSWORD
        gourl = "<a href='"+url_for(:controller => '/people/account', :action => 'new_password') +"'>set a new password</a>"
        explanation = "<p>Your eXtensionID password is incorrect. Please check your password again.  If you have forgotten your password, you can #{gourl} for your eXtensionID.</p>"       
      when AUTH_EMAIL_NOTCONFIRM
        gourl = "<a href='"+url_for(:controller => '/people/account', :action => :confirmemail) +"'>confirm your email address</a>"
        explanation = "<p>You have not yet confirmed your email address. Please #{gourl}.</p>"        
      when AUTH_SIGNUP_CONFIRM
        gourl = "<a href='"+url_for(:controller => '/people/signup', :action => :confirm) +"'>confirm your account and email address</a>"
        explanation = "<p>You have not yet confirmed your email address and account. Please #{gourl}.</p>"        
      when AUTH_ACCOUNT_REVIEW
        gourl = "<a href='"+url_for(:controller => '/people/account', :action => 'review') +"'>Learn more about account reviews</a>"
        explanation = "<p>Your eXtensionID is currently under review. #{gourl}.</p>"         
      when AUTH_ACCOUNT_NOTVOUCHED
        gourl = "<a href='"+url_for(:controller => '/people/account', :action => 'review') +"'>Learn more about account reviews</a>"
        explanation = "<p>Your eXtensionID is currently under review. #{gourl}.</p>"         
      when AUTH_INVALID_EMAIL
        gourl = "<a href='"+url_for(:controller => '/people/profile', :action => :edit) +"'>edit your profile</a>"
        explanation = "<p>Your registered email address is invalid. Please #{gourl} and set a valid email address for your eXtensionID.</p>"      
      when AUTH_ACCOUNT_RETIRED
        gourl = "<a href='"+url_for(:controller => '/people/help', :action => :index)+"'>contact us</a>"
        explanation = "<p>Your eXtensionID has been retired. Please #{gourl} for more information.</p>"
      when AUTH_PASSWORD_EXPIRED
        explanation = "<p>Your eXtensionID password has expired due to inactivity or a retired account. An email has been sent to you with instructions on how to set a new password.</p>"
      when AUTH_INVALID_APIKEY
        explanation = "<p>An internal configuration error has occurred.  Please let us know about this by emailing us at <a href='mailto:eXtensionBugs@extension.org'>eXtensionBugs@extension.org</a>"        
      when AUTH_UNKNOWN
        explanation = "<p>An unknown error occurred. Please let us know about this by emailing us at <a href='mailto:eXtensionBugs@extension.org'>eXtensionBugs@extension.org</a></p>"      
      else
        explanation = "<p>An unknown error occurred. Please let us know about this by emailing us at <a href='mailto:eXtensionBugs@extension.org'>eXtensionBugs@extension.org</a></p>"
    end            
    return explanation
  end
  
  def authlogmsg(resultcode)
    case resultcode
      when AUTH_INVALID_ID
        logmsg = 'invalid eXtensionID'       
      when AUTH_ACCOUNT_RETIRED
        logmsg = 'account retired'
      when AUTH_INVALID_PASSWORD
        logmsg = 'incorrect password'
      when AUTH_PASSWORD_EXPIRED
        logmsg = 'expired password'
      when AUTH_EMAIL_NOTCONFIRM
        logmsg = 'waiting email confirmation'
      when AUTH_SIGNUP_CONFIRM
        logmsg = 'waiting signup confirmation'
      when AUTH_ACCOUNT_REVIEW
        logmsg = 'waiting review'
      when AUTH_ACCOUNT_NOTVOUCHED
        logmsg = 'account not vouched'
      when AUTH_INVALID_EMAIL
        logmsg = 'invalid email address'
      when AUTH_INVALID_APIKEY
        logmsg = 'invalid apikey'
      when AUTH_UNKNOWN
        logmsg = 'unknown account status'
      else
        logmsg = 'not supposed to be here'
    end            
    return logmsg    
  end
  
  def statuscheck(checkuser)
    if(checkuser.account_status == User::STATUS_SIGNUP)
      returnvalues = {:code => AUTH_SIGNUP_CONFIRM, :user => checkuser, :localfail => false}
    elsif(!checkuser.vouched?)
      # reason email? or review?
      if(checkuser.account_status == User::STATUS_CONFIRMEMAIL)
        returnvalues = {:code => AUTH_EMAIL_NOTCONFIRM, :user => checkuser, :localfail => false}
      elsif(checkuser.account_status == User::STATUS_INVALIDEMAIL or checkuser.account_status == User::STATUS_INVALIDEMAIL_FROM_SIGNUP)
        returnvalues = {:code => AUTH_INVALID_EMAIL, :user => checkuser, :localfail => false}
      else
        returnvalues = {:code => AUTH_ACCOUNT_NOTVOUCHED, :user => checkuser, :localfail => false}
      end
    else
      # account status checks
      case checkuser.account_status
      when User::STATUS_CONTRIBUTOR
        returnvalues = {:code => AUTH_SUCCESS, :user => checkuser, :localfail => false}
      when User::STATUS_PARTICIPANT
        returnvalues = {:code => AUTH_SUCCESS, :user => checkuser, :localfail => false}
      when User::STATUS_REVIEWAGREEMENT
        returnvalues = {:code => AUTH_SUCCESS, :user => checkuser, :localfail => false}
       when User::STATUS_REVIEW
         returnvalues = {:code => AUTH_ACCOUNT_REVIEW, :user => checkuser, :localfail => false}
      when User::STATUS_INVALIDEMAIL
        returnvalues = {:code => AUTH_INVALID_EMAIL, :user => checkuser, :localfail => false}
      when User::STATUS_INVALIDEMAIL_FROM_SIGNUP
        returnvalues = {:code => AUTH_INVALID_EMAIL, :user => checkuser, :localfail => false}
      when User::STATUS_CONFIRMEMAIL
        returnvalues = {:code => AUTH_EMAIL_NOTCONFIRM, :user => checkuser, :localfail => false}
      else
        returnvalues = {:code => AUTH_UNKNOWN, :user => checkuser, :localfail => false}
      end
    end
    return returnvalues
  end  
  
  def checkidstring_for_openid(idstring)
    idstring.strip!
    if(/^(http|https):\/\/people.extension.org\/([a-zA-Z]+[a-zA-Z0-9]+)$/ =~ idstring)
      returnid = $2
    elsif(/^people.extension.org\/([a-zA-Z]+[a-zA-Z0-9]+)$/ =~ idstring)
      returnid = $1
    else
      returnid = nil
    end
    return returnid
  end
  
  
  def authuser(idstring,password)
    if(checkid = checkidstring_for_openid(idstring))
      checkuser = User.find(:first, :conditions => ["login = ?", checkid])
    else
      checkuser = User.find(:first, :conditions => ["login = ? OR email = ?", idstring, idstring])
    end
    if(checkuser.nil?)
      returnvalues = {:code => AUTH_INVALID_ID, :user => nil, :localfail => true}
    elsif(checkuser.retired?)
      returnvalues = {:code => AUTH_ACCOUNT_RETIRED, :user => checkuser, :localfail => true}
    elsif(checkuser.password.blank?)
      returnvalues = {:code => AUTH_PASSWORD_EXPIRED, :user => checkuser, :localfail => true}      
    elsif (!checkuser.checkpass(password))
      returnvalues = {:code => AUTH_INVALID_PASSWORD, :user => checkuser, :localfail => true}
    else
      return statuscheck(checkuser)
    end      
  end
end
