# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::QuestionController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory  
  has_rakismet :only => [:report_spam, :report_ham]
 
  def index
    @submitted_question = SubmittedQuestion.find_by_id(params[:id])
    
    if @submitted_question.nil?
      do_404
      return
    end
    
    @categories = Category.root_categories
    @category_options = @categories.map{|c| [c.name,c.id]}
    
    @submitter_name = @submitted_question.submitter_fullname
      
    if @submitted_question.categories and @submitted_question.categories.length > 0
      @category = @submitted_question.categories.first
      @category = @category.parent if @category.parent
      @category_id = @category.id
      @users = @category.users.find(:all, :select => "users.*", :order => "users.first_name")
    # find subcategories
      @sub_category_options = [""].concat(@category.children.map{|sq| [sq.name, sq.id]})
      if subcategory = @submitted_question.categories.find(:first, :conditions => "parent_id IS NOT NULL")
        @sub_category_id = subcategory.id
      end
    else
      @sub_category_options = [""]    
    end
    
  end
  
  def assign
    if request.post?
      if !params[:id]
        flash[:failure] = "You must select a question to assign."
        redirect_to incoming_url
        return
      end
    
      @submitted_question = SubmittedQuestion.find_by_id(params[:id])
      @categories = Category.root_categories
        
      if !@submitted_question
        flash[:failure] = "Invalid question."
        redirect_to incoming_url
        return
      end
    
      if !params[:assignee_login]
        flash[:failure] = "You must select a user to reassign."
        redirect_to :action => :index, :id => @submitted_question
        return
      end
      
      user = User.find_by_login(params[:assignee_login])
      
      if !user or user.retired?
        !user ? err_msg = "User does not exist." : err_msg = "User is retired from the system"
        flash[:failure] = err_msg
        redirect_to :action => :index, :id => @submitted_question
        return
      end
      
      if !user.aae_responder and @currentuser.id != user.id
        flash[:failure] = "This user has elected not to receive questions."
        redirect_to :action => :index, :id => @submitted_question
        return
      end
      
      (params[:assign_comment] and params[:assign_comment].strip != '') ? assign_comment = params[:assign_comment] : assign_comment = nil
      
      if (previous_assignee = @submitted_question.assignee) and (@currentuser != previous_assignee)
        assigned_to_someone_else = true
      end
      
      @submitted_question.assign_to(user, @currentuser, assign_comment)
      # re-open the question if it's reassigned after resolution
      if @submitted_question.status_state == SubmittedQuestion::STATUS_RESOLVED or @submitted_question.status_state == SubmittedQuestion::STATUS_NO_ANSWER
        @submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED)
        SubmittedQuestionEvent.log_reopen(@submitted_question, user, @currentuser, assign_comment)
      end
      
      redirect_to :action => 'index', :id => @submitted_question
    else
      do_404
      return
    end
  end
  
  def assign_to_wrangler
    if request.post? and params[:squid]
      submitted_question = SubmittedQuestion.find_by_id(params[:squid])
      recipient = submitted_question.assign_to_question_wrangler(@currentuser)
      # re-open the question if it's reassigned after resolution
      if submitted_question.status_state == SubmittedQuestion::STATUS_RESOLVED or submitted_question.status_state == SubmittedQuestion::STATUS_NO_ANSWER
        submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED)
        SubmittedQuestionEvent.log_reopen(submitted_question, recipient, @currentuser, SubmittedQuestion::WRANGLER_REASSIGN_COMMENT)
      end
      
    else
      do_404
      return
    end
    
    redirect_to :action => :index, :id => submitted_question.id
  end
  
  def enable_category_change
    if request.post?
      @submitted_question = SubmittedQuestion.find_by_id(params[:id])
  
      @category_options = Category.root_categories.map{|c| [c.name,c.id]}
      if parent_category = @submitted_question.categories.find(:first, :conditions => "parent_id IS NULL")
        @category_id = parent_category.id
        @sub_category_options = [""].concat(parent_category.children.map{|sq| [sq.name, sq.id]})
        if subcategory = @submitted_question.categories.find(:first, :conditions => "parent_id IS NOT NULL")
          @sub_category_id = subcategory.id
        end
      else
        @sub_category_options = [""]
      end
      render :layout => false
    end
  end
  
  def change_category
    if request.post?
      @submitted_question = SubmittedQuestion.find(params[:sq_id].strip)
      category_param = "category_#{@submitted_question.id}"
      parent_category = Category.find(params[category_param].strip) if params[category_param] and params[category_param].strip != '' and params[category_param].strip != "uncat"
      sub_category = Category.find(params[:sub_category].strip) if params[:sub_category] and params[:sub_category].strip != ''
      @submitted_question.categories.clear
      if params[category_param].strip != "uncat"
        @submitted_question.categories << parent_category if parent_category
        @submitted_question.categories << sub_category if sub_category
      end
      @submitted_question.save
      SubmittedQuestionEvent.log_recategorize(@submitted_question, @currentuser, @submitted_question.category_names)
    end
    
    respond_to do |format|
      format.js
    end
    
  end
  
  # Show the expert form to answer a question
  def answer
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    
    if !@submitted_question
      flash[:failure] = "Invalid question."
      redirect_to incoming_url
      return
    end
    
    if @submitted_question.resolved?
      flash[:failure] = "This question has already been resolved.<br />It could have been resolved while you were working on it.<br />We appreciate your help in resolving these questions!"
      redirect_to :action => :index, :id => @submitted_question.id
      return
    end
    
    @status = params[:status_state]
    # if expert chose a SearchQuestion to answer this with, find that so that we can 
    # attach that to the submitted question as a contributing question
    @question = SearchQuestion.find_by_id(params[:question]) if params[:question]
    @sampletext = params[:sample] if params[:sample]
    signature_pref = @currentuser.user_preferences.find_by_name('signature')
    signature_pref ? @signature = signature_pref.setting : @signature = "-#{@currentuser.fullname}"
    
  
    if request.post?
      answer = params[:current_response]

      if !answer or '' == answer.strip
        @signature = params[:signature]
        flash[:failure] = "You must not leave the answer blank."
        return
      end
      
      @question ? contributing_question = @question.id : contributing_question = nil
      (@status and @status.to_i == SubmittedQuestion::STATUS_NO_ANSWER) ? sq_status = SubmittedQuestion::STATUS_NO_ANSWER : sq_status = SubmittedQuestion::STATUS_RESOLVED
      
      @submitted_question.add_resolution(sq_status, @currentuser, answer, contributing_question)
          
      if params[:signature] and params[:signature].strip != ''
        @signature = params[:signature]
      else
        @signature = ''
      end
      
      Notification.create(:notifytype => Notification::AAE_PUBLIC_EXPERT_RESPONSE, :user => User.systemuser, :creator => @currentuser, :additionaldata => {:submitted_question_id => @submitted_question.id, :signature => @signature })  	    
        
      redirect_to :action => 'question_answered', :squid => @submitted_question.id
    end

  end
  
  # Display the confirmation for answering a question
  def question_answered
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    
    if !@submitted_question
      flash[:failure] = "Invalid question."
      redirect_to incoming_url
      return
    end

  end
  
  def close_out
    @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
    @submitted_question.update_attributes(:status => SubmittedQuestion::RESOLVED_TEXT, :status_state => SubmittedQuestion::STATUS_RESOLVED)
    
    SubmittedQuestionEvent.log_close(@submitted_question, @currentuser)
    redirect_to :action => :index, :id => @submitted_question.id
  end
  
  def toggle_public_view
    if request.post?
      if @currentuser.is_admin?
        submitted_question = SubmittedQuestion.find(params[:id])
        if submitted_question.show_publicly?
          submitted_question.update_attribute(:show_publicly, false)
          flash[:success] = "Question has been removed from public view."
        else
          submitted_question.update_attribute(:show_publicly, true)
          flash[:success] = "Question has been made publicly viewable."
        end
      else
        flash[:warning] = "You must be an administrator to access this feature."
      end
      redirect_to :action => :index, :id => submitted_question.id
    else
      do_404
      return
    end
  end
  
  def reserve_question
    if request.post?
      if params[:sq_id] and @submitted_question = SubmittedQuestion.find_by_id(params[:sq_id].strip) 
        if @submitted_question.resolved?
          flash[:failure] = "This question has already been resolved"
          redirect_to aae_question_url(:id => @submitted_question.id)
          return
        end
        if (@submitted_question.assignee) and (@currentuser.id != @submitted_question.assignee.id)
          previous_assignee_email = @submitted_question.assignee.email
          @submitted_question.assign_to(@currentuser, @currentuser, nil) 
        end
        SubmittedQuestionEvent.log_working_on(@submitted_question, @currentuser)
        redirect_to aae_question_url(:id => @submitted_question.id)
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
      submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]])
      if submitted_question
        submitted_question.update_attributes(:spam => true, :show_publicly => false)
        SubmittedQuestionEvent.log_spam(submitted_question, @currentuser)       
        
        begin
          submitted_question.spam!
        rescue Exception => ex
          logger.error "Problem reporting spam with rakismet for question # #{submitted_question.id} at #{Time.now.to_s}\nError: #{ex.message}"  
        end
        
        flash[:success] = "Incoming question has been successfully marked as spam."
      else
        flash[:failure] = "Incoming question does not exist."
      end
      redirect_to incoming_url
    else
      do_404
      return
    end
  end

  def report_ham
    if request.post?
      submitted_question = SubmittedQuestion.find(:first, :conditions => ["id = ?", params[:id]])
      if submitted_question
        submitted_question.update_attributes(:spam => false, :show_publicly => true)
        SubmittedQuestionEvent.log_non_spam(submitted_question, @currentuser)
          
        begin
          submitted_question.ham!
        rescue Exception => ex
          logger.error "Problem reporting ham with rakismet for question # #{submitted_question.id} at #{Time.now.to_s}\nError: #{ex.message}"
        end
        
        flash[:success] = "Incoming question has been successfully marked as non-spam."
        redirect_to aae_question_url(:id => submitted_question.id)
      else
        flash[:failure] = "Incoming question does not exist."
        redirect_to spam_url
      end  
    end   
  end
  
  def reject    
    filteredparams = ParamsFilter.new([:squid],params)
    
    @submitted_question = filteredparams.squid
    
    if(@submitted_question.nil?)
      flash[:failure] = "Question not found."
      redirect_to incoming_url
    end
    
    @submitter_name = @submitted_question.submitter_fullname
      
    if @submitted_question.resolved?
      flash[:failure] = "This question has already been resolved."
      redirect_to aae_question_url(:id => @submitted_question)
      return
    end
      
    if request.post?
      filteredparams = ParamsFilter.new([:reject_message => :string],params)
      message = filteredparams.reject_message
      
      if message.blank?
        flash.now[:failure] = "Please document a reason for rejecting this question."
        render nil
        return
      end
        
      if @submitted_question.resolved?
        flash.now[:failure] = "This question has already been resolved."
        render nil
        return
      end   

      @submitted_question.add_resolution(SubmittedQuestion::STATUS_REJECTED, @currentuser, message)
        
      if @submitted_question.assignee and (@currentuser.id != @submitted_question.assignee.id)
        Notification.create(:notifytype => Notification::AAE_REJECT, :user => @submitted_question.assignee, :creator => @currentuser, :additionaldata => {:submitted_question_id => @submitted_question.id, :reject_message => message})  	    
      end
        
      flash[:success] = "The question has been rejected."
      redirect_to aae_question_url(:id => @submitted_question)  
    end        
  end
  
  def reactivate
    if request.post?
      @submitted_question = SubmittedQuestion.find_by_id(params[:id])
      @submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED, :resolved_by => nil, :current_response => nil, :resolved_at => nil, :resolver_email => nil, :show_publicly => true)
      SubmittedQuestionEvent.log_reactivate(@submitted_question, @currentuser)
      flash[:success] = "Question re-activated"
      redirect_to aae_question_url(:id => @submitted_question.id)
    end
  end
  
  def get_counties
    if !params[:location_fips] or params[:location_fips].strip == '' or !(location = Location.find_by_fipsid(params[:location_fips]))
      @counties = nil
    else
      @counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    end
    
    render :layout => false
  end
  
  def escalation_report
    @filterparams = FilterParams.new(params)
    sincehours = AppConfig.configtable['aae_escalation_delta'] = 24
    @category = @filterparams.legacycategory
    @submitted_questions = SubmittedQuestion.escalated(sincehours).filtered({:category => @filterparams.legacycategory}).listdisplayincludes.ordered('submitted_questions.last_opened_at asc')
  end
  
end