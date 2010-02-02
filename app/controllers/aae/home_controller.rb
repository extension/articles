# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::HomeController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory
    
  def index
    return redirect_to(incoming_url)
  end
  
end