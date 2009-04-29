# === COPYRIGHT:
#  Copyright (c) 2005-2007 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

#require 'account_helper'

class HelpController < ApplicationController
  layout 'people'
  
  def index
     @page = params[:id]
     if !@page.nil?
       @feed_text = HelpFeed.fetch_feed(@page)
     else
       @feed_text = ""
     end
   end

  def contactform
    @isloggedin = checklogin
        
    if request.post?
      @contact = Contact.new(params[:contact])
      if(@isloggedin)
        @contact.loggedin = true
        @contact.login = @currentuser.login
        @contact.name = @currentuser.first_name+' '+@currentuser.last_name
        @contact.email = @currentuser.email
      else
        @contact.loggedin = false
      end
      if (@contact.valid?)
        send_contact_email(@contact)
      end
      flash[:success] = "Thank you for your comments, we'll respond soon!"
      redirect_to(:controller => 'welcome', :action => 'home')
    end
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
  
  def send_contact_email(contact)
    addinfo = Hash.new
    addinfo['remoteaddr'] = request.env["REMOTE_ADDR"]
    addinfo['useragent'] = request.env["HTTP_USER_AGENT"]
    addinfo['version'] = AppVersion.version

    if contact.loggedin
      addinfo['reviewurl'] = url_for(:controller => 'admin', :action => 'showuser', :id => contact.login)
    end
    email = HelpMailer.create_contact_email(contact,addinfo)
    begin
      HelpMailer.deliver(email)    
    rescue
      logger.error("Unable to deliver contact email.");
      return false
    end
    return true    
  end
end