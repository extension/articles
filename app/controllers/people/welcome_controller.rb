# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class WelcomeController < ApplicationController
  include AuthCheck
  
  layout 'people'
  before_filter :login_required
  before_filter :check_purgatory,:except => [:notice] 
  
  def home
    @openidmeta = openidmeta(@openiduser)
  end
  
  def notice
    result = statuscheck(@currentuser)
    if(AUTH_SUCCESS == result[:code])
      redirect_to(:controller=>:welcome, :action =>:home)
    else
      @notice = explainauthresult(result[:code])
    end
  end

end