# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class NoticeController < ApplicationController
  layout 'frontporch'  
  def ask
    render :layout => false
  end

  def admin_required
    @right_column = false 
  end

end