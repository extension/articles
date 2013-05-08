# === COPYRIGHT:
# Copyright (c) 2012 North Carolina State University
# === LICENSE:
# see LICENSE file
class AuthController < ApplicationController
  skip_before_filter :signin_required
  skip_before_filter :verify_authenticity_token

  def start
  end
    
  def end
    set_current_person(nil)
    flash[:success] = "You have successfully signed out."
    return redirect_to(root_url)
  end
  
  def success
    authresult = request.env["omniauth.auth"]    
    uid = authresult['uid']
    email = authresult['info']['email']
    name = authresult['info']['name']
    nickname = authresult['info']['nickname']

    logger.debug "#{authresult.inspect}"
     
    person = Person.find_by_uid(uid)
    
    if(person)
      if(person.retired?)
        flash[:error] = "Your account is currently marked as retired."
        return redirect_to(root_url)
      else
        set_current_person(person)
        flash[:success] = "You are signed in as #{current_person.fullname}"
      end
    else
      flash[:error] = "Unable to find your account, please contact an Engineering staff member to create your account"
    end
  
    return www_redirect_back_or_default(root_url)

  end
  
  def failure
    logger.debug(request.env["omniauth.auth"].inspect)
  end
  
  

end