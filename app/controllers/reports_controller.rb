# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ReportsController < ApplicationController
  
  def index    
    set_title("Reports")
    set_titletag("Reports - eXtension")
    @right_column = false
  end
  
end
