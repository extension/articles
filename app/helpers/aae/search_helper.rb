# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

module Aae::SearchHelper

  def is_checked(search_mode)
    if !session[:aae_search] or session[:aae_search] == []
      session[:aae_search] = ['faq', 'aae']
      if search_mode == 'faq' || search_mode == 'aae'
        return true
      else
        return false
      end
    else
      if session[:aae_search].include?(search_mode)
        return true
      else
        return false
      end
    end
  end
  
end