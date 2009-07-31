# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::IncomingController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required

  # Lists unresolved ask an expert questions
  def index 
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
  
    #set the instance variables based on parameters
    list_view
    set_filters
  
    @reserved_questions = SubmittedQuestionEvent.reserved_questions.collect{|sq| sq.id}
    @questions_status = SubmittedQuestion::STATUS_SUBMITTED
    @submitted_questions = SubmittedQuestion.find_submitted_questions(SubmittedQuestion::SUBMITTED_TEXT, @category, @location, @county, @source, nil, nil, params[:page], true, false, @order)
  end
  
  
end