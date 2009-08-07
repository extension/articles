# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::SpamListController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required
  
  def index
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    #set the instance variables based on parameters  
    list_view
    set_filters
    
    # it does not matter if this question was previously reserved if it's spam
    @reserved_questions = []
    @questions_status = SubmittedQuestion::STATUS_SUBMITTED
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
    @submitted_questions = SubmittedQuestion.submittedspam.filtered(filteroptions).ordered(@order).listdisplayincludes.paginate(:page => params[:page])
  end
  
end