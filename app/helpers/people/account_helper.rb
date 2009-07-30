# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module People::AccountHelper
  
  def login_prompt_string
    if(!session[:last_opierequest])
      return 'Please Login'
    else
      if(trust_root = session[:last_opierequest].trust_root)
        # try and parse the domain out of the trust_root
        begin 
          loginuri = URI.parse(trust_root)
        rescue
          return 'Please Login'
        end  
        
        if(!loginuri.host.nil?)
          return "Please Login for #{loginuri.host}"
        else
          return 'Please Login'
        end
      else
        return 'Please Login'
      end
    end
  end
end
