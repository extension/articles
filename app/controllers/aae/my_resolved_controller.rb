# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::MyResolvedController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required
  
  def index
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    #set the instance variables based on parameters
    list_view(true)
    set_filters
    @questions_status = SubmittedQuestion::STATUS_RESOLVED
    @user = @currentuser
    
    # user's resolved submitted questions filtered by submitted question filter
    @filtered_submitted_questions = SubmittedQuestion.find_submitted_questions(SubmittedQuestion::RESOLVED_TEXT, @category, @location, @county, @source, @user, nil, params[:page], true, false, @order)
    
    # total user's resolved submitted questions (unfiltered)
    @total_submitted_questions = SubmittedQuestion.find_submitted_questions(SubmittedQuestion::RESOLVED_TEXT, nil, nil, nil, nil, @user, nil, params[:page], true, false, @order)  
    
    # the difference in count between the filtered and unfiltered questions
    @question_difference = @total_submitted_questions.total_entries - @filtered_submitted_questions.total_entries
    
    # decide which set of submitted questions (filtered or unfiltered) get shown in the list view
    @filtered_submitted_questions.total_entries == 0 ? @submitted_questions = @total_submitted_questions : @submitted_questions = @filtered_submitted_questions
  end
  
end