# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::DashboardController < ApplicationController

  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory

  
  def index
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    #set the instance variables based on parameters 
   list_view
   set_filters
   filter_string_helper
  
   @filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
   @submitted_questions = SubmittedQuestion.submitted.filtered(@filteroptions).ordered(@order).listdisplayincludes.all    
  end
  
  
  
end