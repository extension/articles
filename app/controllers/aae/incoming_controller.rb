# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::IncomingController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory

  # Lists unresolved ask an expert questions
  def index 
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
  
    #set the instance variables based on parameters
    list_view
    set_filters
    filter_string_helper
  
    @reserved_questions = SubmittedQuestionEvent.reserved_questions.collect{|sq| sq.id}
    @questions_status = SubmittedQuestion::STATUS_SUBMITTED
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source}
    ActiveRecord::Base::logger.debug "filteroptions = #{filteroptions.inspect}"
    @submitted_questions = SubmittedQuestion.submitted.filtered(filteroptions).ordered(@order).listdisplayincludes.paginate(:page => params[:page])
  end
  
  
end