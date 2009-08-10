# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::ResolvedController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required
  
  def index
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    # set the instance variables based on parameters
    list_view(true)
    set_filters
    
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
    
    case params[:type]
    when 'all'
      sq_query_method = SubmittedQuestion::RESOLVED_TEXT
      @questions_status = SubmittedQuestion::STATUS_RESOLVED
    when nil
      sq_query_method = SubmittedQuestion::RESOLVED_TEXT
      @questions_status = SubmittedQuestion::STATUS_RESOLVED
    when 'answered'
      sq_query_method = SubmittedQuestion::ANSWERED_TEXT
      @questions_status = SubmittedQuestion::ANSWERED_TEXT
      @page_title = 'Resolved/Answered Questions'
    when 'not_answered'
      sq_query_method = SubmittedQuestion::NO_ANSWER_TEXT
      @questions_status = SubmittedQuestion::STATUS_NO_ANSWER
      @page_title = 'Resolved/Not Answered Questions'
    when 'rejected'
      sq_query_method = SubmittedQuestion::REJECTED_TEXT
      @questions_status = SubmittedQuestion::STATUS_REJECTED
      @page_title = 'Resolved/Rejected Questions'
    else
      flash.now[:failure] = "Wrong type of resolved questions specified."
      @submitted_questions = []
      return
    end
    
    # skip the joins because we are including them already with listdisplayincludes
    filteroptions.merge!({:skipjoins => true})
    @submitted_questions = SubmittedQuestion.send(sq_query_method).filtered(filteroptions).ordered(@order).listdisplayincludes.paginate(:page => params[:page])    
    
  end
  
end