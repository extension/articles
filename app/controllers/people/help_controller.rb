# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

#require 'account_helper'

class People::HelpController < ApplicationController
  layout 'people'
  
  def index
    redirect_to(:action => :contactform)
  end

  def contactform
    @isloggedin = checklogin
  end

  private
  
  def checklogin
    if session[:userid]
      checkuser = User.find_by_id(session[:userid])
      if not checkuser
        return false
      else
        @currentuser = checkuser
        return true
      end
    else
      return false
    end
  end

end