# === COPYRIGHT:
#  Copyright (c) 2005-2008 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module UsersHelper
  def send_token_confirmation(token)
    urls = Hash.new
    case token.tokentype
      when UserToken::RESETPASS
        urls['directurl'] = url_for(:controller => 'users', :action => 'new_password', :token => token.token)
        urls['manualurl'] = url_for(:controller => 'users', :action => 'new_password') 
        urls['contactus'] = url_for(:controller => 'main', :action => 'contactform')       
        email = MainMailer.create_confirm_password(token,urls)
      else 
        logger.error("Invalid token type.");
        return false
    end
  
    begin
      MainMailer.deliver(email)    
    rescue
      logger.error("Unable to deliver confirmation email.");
      return false
    end
    return true
  end
end