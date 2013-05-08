# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class NoticeController < ApplicationController
  layout 'pubsite'  
  def ask
    render :layout => false
  end

  def admin_required
    @right_column = false 
  end

end