# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Ask::ExpertController < ApplicationController
  
  
  
  

  def reject    
    @submitted_question = SubmittedQuestion.find_by_id(params[:id])
    @submitter_name = @submitted_question.submitter_fullname
    if @submitted_question  
      if @submitted_question.resolved?
        flash[:failure] = "This question has already been resolved."
        redirect_to :controller => :expert, :action => :question, :id => @submitted_question
        return
      end
      
      if request.post?
        message = params[:reject_message]
        if message.nil? or message.strip == ''
          flash.now[:failure] = "Please document a reason for the rejecting this question."
          render nil
          return
        end
        
        if @submitted_question.resolved?
          flash.now[:failure] = "This question has already been resolved."
          render nil
          return
        end   

        if @submitted_question.reject(@currentuser, message)
          flash[:success] = "The question has been rejected."
          redirect_to :controller => :expert, :action => :question, :id => @submitted_question
        else
          flash[:failure] = "The question did not get properly saved. Please try again."
          render :action => :reject
        end
      end        
    else
      flash[:failure] = "Question not found."
      redirect_to incoming_url
    end
  end
  
  def reactivate
    if request.post?
      @submitted_question = SubmittedQuestion.find_by_id(params[:id])
      @submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED, :resolved_by => nil, :current_response => nil, :resolved_at => nil, :resolver_email => nil)
      SubmittedQuestionEvent.log_reactivate(@submitted_question, @currentuser)
      flash[:success] = "Question re-activated"
      redirect_to :controller => :expert, :action => :question, :id => @submitted_question.id
    end
  end

  private
   
  def setup_cat_loc
    @location_options = [""].concat(ExpertiseLocation.find(:all, :order => 'entrytype, name').map{|l| [l.name, l.fipsid]})
    @categories = Category.root_categories
    @category_options = @categories.map{|c| [c.name,c.id]}
    
    @county_fips = @county.fipsid if @county  
    @category_id = @category.id if @category
    @location_fips = @location.fipsid if @location
    
    # ToDo: need to change this id parameter name to something more descriptive
    @submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]]) if not @submitted_question
    @users = User.find_by_cat_loc(@category, @location, @county)
  end
  
end
