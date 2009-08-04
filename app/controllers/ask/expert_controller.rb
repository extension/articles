# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'zip_code_to_state'

class Ask::ExpertController < ApplicationController
  layout 'aae'
  
  before_filter :filter_string_helper, :only => [:incoming, :assigned, :my_resolved, :resolved]
  before_filter :login_required
  
  UNASSIGNED = "uncategorized"
  ALL = "all"
  
  def help
    render :template => 'help/contactform.html.erb'
  end
  
  def location
    if params[:id]
      @location = ExpertiseLocation.find(:first, :conditions => ["fipsid = ?", params[:id].to_i])
      if !@location
        flash[:failure] = "Invalid Location Entered"
        redirect_to home_url
      else
        @users = @location.users.find(:all, :order => "users.first_name")
      end
    else
      flash[:failure] = "Invalid Location Entered"
      redirect_to home_url
    end
  end
  
  def show_profile
    @user = User.find(params[:id])
    respond_to do |format|
      format.js
    end
  end
  
  def category
    #if all users with an expertise in a category were selected
    if params[:id]
      @category = Category.find(:first, :conditions => ["id = ?", params[:id].strip])
      
      if @category
        @category_name = @category.name
        @users = @category.users
        @combined_users = get_answering_users(@users) if @users.length > 0
      else
        flash[:failure] = "Invalid Category"
        request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to home_url)
        return
      end
    else
      flash[:failure] = "Invalid Category"
      request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to home_url)
      return
    end
  end
 
  # Get counties for location selected for aae question filtering
  def get_aae_counties
    if params[:location] and params[:location].strip != Location::ALL
      location = Location.find(:first, :conditions => ["fipsid = ?", params[:location].strip])
      @counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    else
      @counties = nil
    end
    render :layout => false
  end
 
  def reserve_question
    if request.post?
      if params[:sq_id] and @submitted_question = SubmittedQuestion.find_by_id(params[:sq_id].strip) 
        if @submitted_question.resolved?
          flash[:failure] = "This question has already been resolved"
          redirect_to :action => :question, :id => @submitted_question.id
          return
        end
        if @currentuser.id != @submitted_question.assignee.id
          previous_assignee_email = @submitted_question.assignee.email
          @submitted_question.assign_to(@currentuser, @currentuser, nil) 
        end
        SubmittedQuestionEvent.log_working_on(@submitted_question, @currentuser)
        redirect_to :action => :question, :id => @submitted_question.id
      else
        flash[:failure] = "Invalid submitted question number."
        redirect_to incoming_url
      end
    else
      do_404
      return
    end
  end

  def get_subcats
    parent_cat = Category.find_by_id(params[:category].strip) if params[:category] and params[:category].strip != '' and params[:category].strip != "uncat"
    if parent_cat 
      @sub_category_options = [""].concat(parent_cat.children.map{|sq| [sq.name, sq.id]})
    else
      @sub_category_options = [""]
    end
    
    render :layout => false
  end
  
  def report_spam
    if request.post?      
      begin
        submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]])
        if submitted_question
          submitted_question.update_attribute(:spam, true)
          SubmittedQuestionEvent.log_spam(submitted_question, @currentuser)       
          submitted_question.spam!
          flash[:success] = "Incoming question has been successfully marked as spam."
        else
          flash[:failure] = "Incoming question does not exist."
        end
        
      rescue Exception => ex
        flash[:failure] = "There was a problem reporting spam. Please try again at a later time."
        logger.error "Problem reporting spam at #{Time.now.to_s}\nError: #{ex.message}"
      end
      redirect_to incoming_url
    end
  end

  def report_ham
    if request.post?
      begin
        submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]])
        if submitted_question
          submitted_question.update_attribute(:spam, false)
          SubmittedQuestionEvent.log_non_spam(submitted_question, @currentuser)
          submitted_question.ham!
          flash[:success] = "Incoming question has been successfully marked as non-spam."
          redirect_to :controller => :expert, :action => :question, :id => submitted_question.id
          return
        else
          flash[:failure] = "Incoming question does not exist."
        end
        
      rescue Exception => ex
        flash[:failure] = "There was a problem marking this question as non-spam. Please try again at a later time."
        logger.error "Problem reporting ham at #{Time.now.to_s}\nError: #{ex.message}"
      end
        
      redirect_to spam_url
    end   
  end

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
  
  def get_answering_users(selected_users)
    user_ids = selected_users.map{|u| u.id}.join(',')
    answering_role = Role.find_by_name(Role::AUTO_ROUTE)
    answering_users = answering_role.users.find(:all, :select => "users.*", :conditions => "users.id IN (#{user_ids})")
    user_intersection = selected_users & answering_users
  end
  
end
