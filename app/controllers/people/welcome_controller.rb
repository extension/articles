# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class People::WelcomeController < ApplicationController
  include AuthCheck
  
  layout 'people'
  before_filter :login_required
  before_filter :check_purgatory,:except => [:notice] 
  
  def home
    @openidmeta = openidmeta(@openiduser)
    # if we get here for some reason, clear last_opierequest
    session[:last_opierequest] = nil
  end
  
  def notice
    result = statuscheck(@currentuser)
    if(AUTH_SUCCESS == result[:code])
      redirect_to(people_welcome_url)
    else
      @notice = explainauthresult(result[:code])
    end
  end

end