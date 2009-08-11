# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::MyResolvedController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory
  
  def index
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    #set the instance variables based on parameters
    list_view(true)
    set_filters
    filter_string_helper
    @questions_status = SubmittedQuestion::STATUS_RESOLVED
    @user = @currentuser

    # user's resolved submitted questions filtered by submitted question filter
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source, :resolved_by => @user}
    @filtered_submitted_questions = SubmittedQuestion.resolved.filtered(filteroptions).ordered(@order).listdisplayincludes.paginate(:page => params[:page])
      
    # total user's resolved submitted questions (unfiltered)
    @total_submitted_questions = SubmittedQuestion.resolved.filtered({:resolved_by => @user}).ordered(@order).listdisplayincludes.paginate(:page => params[:page])
    
    # the difference in count between the filtered and unfiltered questions
    @question_difference = @total_submitted_questions.total_entries - @filtered_submitted_questions.total_entries
    
    # decide which set of submitted questions (filtered or unfiltered) get shown in the list view
    @filtered_submitted_questions.total_entries == 0 ? @submitted_questions = @total_submitted_questions : @submitted_questions = @filtered_submitted_questions
  end
  
end