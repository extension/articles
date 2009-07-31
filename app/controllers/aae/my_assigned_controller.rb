# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::MyAssignedController < ApplicationController
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
    @questions_status = SubmittedQuestion::STATUS_SUBMITTED
    if params[:id]
      @user = User.find_by_id(params[:id])
      
      if !@user
        flash[:failure] = "Invalid user."
        go_back
        return
      end
      
    else
      @user = @currentuser
    end
    
    # find questions that are marked as being currently worked on
    @reserved_questions = SubmittedQuestionEvent.reserved_questions.collect{|sq| sq.id}
    
    # user's assigned submitted questions filtered by submitted question filter
    @filtered_submitted_questions = SubmittedQuestion.find_submitted_questions(SubmittedQuestion::SUBMITTED_TEXT, @category, @location, @county, @source, nil, @user, nil, false, false, @order)
    
    # total user's assigned submitted questions (unfiltered)
    @total_submitted_questions = SubmittedQuestion.find_submitted_questions(SubmittedQuestion::SUBMITTED_TEXT, nil, nil, nil, nil, nil, @user, nil, false, false, @order)

    # the difference in count between the filtered and unfiltered questions
    @question_difference = @total_submitted_questions.length - @filtered_submitted_questions.length
    
    @questions_not_in_filter = @total_submitted_questions - @filtered_submitted_questions if @question_difference > 0
    
    # decide which set of submitted questions (filtered or unfiltered) get shown in the list view
    @filtered_submitted_questions.length == 0 ? @submitted_questions = @total_submitted_questions : @submitted_questions = @filtered_submitted_questions
  end
  
  
end