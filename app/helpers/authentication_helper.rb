# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# Methods added to this helper will be available to all templates in the application.
require 'uri'
module AuthenticationHelper
   
  def admin_mode?
    if(!@currentuser.nil? && @currentuser.is_admin? && session[:adminmode] == @currentuser.id.to_s)
      return true
    else
      return false
    end
  end
  
  def admin_mode_text(mode='checkcookie')
    turned_on_text = "<strong class=\"on\">ON</strong> "+link_to_remote('off', {:url => {:controller => '/admin', :action => :setadminmode, :mode => 'off', :currenturi => Base64.encode64(request.request_uri)}, :method => :post}, :title => "Turn off admin mode for your account")
    turned_off_text = "<strong class=\"off\">OFF</strong> "+link_to_remote('on', {:url => {:controller => '/admin', :action => :setadminmode, :mode => 'on', :currenturi => Base64.encode64(request.request_uri)}, :method => :post}, :title => "Turn on admin mode for your account")
    if(mode == 'on')
      "#{turned_on_text}"
    elsif(mode == 'off')
      "#{turned_off_text}"
    else
      admin_mode? ? "#{turned_on_text}" : "#{turned_off_text}"
    end
  end
  
end