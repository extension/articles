# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::HelpController < ApplicationController
  layout 'aae'
  before_filter :login_required
  
  def index
    return render :template => 'help/contactform.html.erb'
  end

end