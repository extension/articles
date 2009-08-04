# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::QuestionController < ApplicationController
  layout 'aae'
  before_filter :filter_string_helper
  before_filter :login_required
 
  def index
    @submitted_question = SubmittedQuestion.find_by_id(params[:id])
    
    if @submitted_question.nil?
      do_404
      return
    end
    
    @contributing_question = @submitted_question.contributing_question
    if @contributing_question
      @contributing_question.entrytype == SearchQuestion::FAQ ? @type = 'FAQ' : @type = 'AaE Question'
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
    if !params[:id]
      flash[:failure] = "You must select a question to assign."
      go_back
      return
    end
    
    @submitted_question = SubmittedQuestion.find_by_id(params[:id])
    @categories = Category.root_categories
        
    if !@submitted_question
      flash[:failure] = "Invalid question."
      go_back
      return
    end
    
    if @submitted_question.resolved?
      flash[:failure] = "Question has already been resolved."
      redirect_to :action => :question, :id => @submitted_question
      return
    end
    
    if request.post?
      if !params[:assignee_login]
        flash[:failure] = "You must select a user."
        go_back
        return
      end
      
      user = User.find_by_login(params[:assignee_login])
      
      if !user or user.retired?
        !user ? err_msg = "User does not exist." : err_msg = "User is retired from the system"
        flash[:failure] = err_msg
        go_back
        return
      end
      
      (params[:assign_comment] and params[:assign_comment].strip != '') ? assign_comment = params[:assign_comment] : assign_comment = nil
      
      if (previous_assignee = @submitted_question.assignee) and (@currentuser != previous_assignee)
        assigned_to_someone_else = true
      end
      
      @submitted_question.assign_to(user, @currentuser, assign_comment)
      redirect_to :action => 'question', :id => @submitted_question
    end
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
      redirect_to :action => :question, :id => @submitted_question.id
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
      
      @submitted_question.update_attributes(:status => SubmittedQuestion.convert_to_string(sq_status), :status_state =>  sq_status, :resolved_by => @currentuser, :current_response => answer, :resolver_email => @currentuser.email, :current_contributing_question => contributing_question)  
          
      if params[:signature] and params[:signature].strip != ''
        @signature = params[:signature]
      else
        @signature = ''
      end
      
      Notification.create(:notifytype => Notification::AAE_PUBLIC_EXPERT_RESPONSE, :user => User.systemuser, :creator => @currentuser, :additionaldata => {:submitted_question_id => @submitted_question.id, :signature => @signature })  	    
      flash[:success] = "Your answer has been sent to the person who asked the question.<br />
                        You can now save the question as an FAQ, or exit this screen without saving."
        
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
  
end