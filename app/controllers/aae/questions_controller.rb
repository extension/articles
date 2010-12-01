# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::QuestionsController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory  
  
  def submitter
    filteredparams = ParamsFilter.new([:account],params)
    if(filteredparams.account.nil?)
      return list_view_error("Invalid account specified.")
    else
      @submitter = filteredparams.account
    end
    
    # too afraid to change all this right now.
    if err_msg = params_errors
      list_view_error(err_msg)
      return
    end
    
    # set the instance variables based on parameters
    list_view(true)
    set_filters
    filter_string_helper
    filteroptions = {:category => @category, :location => @location, :county => @county, :source => @source, :submitter_id => @submitter.id}    
    @submitted_questions = SubmittedQuestion.filtered(filteroptions).ordered(@order).listdisplayincludes.paginate(:page => params[:page])    
  end
  
end