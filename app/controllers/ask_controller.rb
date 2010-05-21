# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class AskController < ApplicationController  
  has_rakismet :only => [:submission_form]
  before_filter :login_optional
  
  layout 'pubsite'
  
  #TODO:  this controller needs to be refactored, there's too much duplication of validation logic across methods 
  
  def index
    @right_column = false
    set_title("Ask an Expert - eXtension", "New Question")
    
    # if we are editing
    if params[:q]
      flash.now[:googleanalytics] = '/ask-an-expert-edit-question'
      set_titletag("Edit your Question - eXtension")
      @question = params[:q].sanitize
    else
      flash.now[:googleanalytics] = '/ask-an-expert-form'
      set_titletag("Ask an Expert - eXtension")
    end    
  end
  
  def submission_form
    @categories = [""].concat(Category.launched_content_categories.map{|c| [c.name, c.id]})
    @location_options = get_location_options
    @county_options = get_county_options
    
    if request.get?  
      if !params[:q].blank?  
        @submitted_question = SubmittedQuestion.new(:asked_question => params[:q].sanitize)
        @right_column = false
        session[:return_to] = params[:redirect_to]
        flash.now[:googleanalytics] = '/ask-an-expert-submission-form'
    
        set_title("Ask an Expert - eXtension", "New Question")
        set_titletag("Ask an Expert - eXtension")

        if(!session[:public_user_id].nil?)
          @public_user = PublicUser.find_by_id(session[:public_user_id]) || PublicUser.new
        elsif(!@currentuser.nil?)
          # let's get cute and fill in the name/email
          @public_user = PublicUser.new(:email => @currentuser.email, :first_name => @currentuser.first_name, :last_name => @currentuser.last_name)
        else
          @public_user = PublicUser.new
        end  
      # question was blank
      else
        flash[:notice] = "Please fill in the question field before submitting."
        redirect_to :action => :index
      end
    # Question asker submits the question (ie. POST request)
    else
      # need to use filter params here
      if(params[:submitted_question][:asked_question].blank? or params[:public_user].blank?)
        return_error = "Please fill in all required fields."
      elsif params[:public_user][:email].blank? or params[:public_email_confirmation].blank?
        return_error = "Please enter an email address and email address confirmation."
      elsif params[:public_user][:email].strip != params[:public_email_confirmation].strip
        return_error = "Your email address confirmation does not match.<br />Please make sure your email address and confirmation match up."
      end

      @public_user = PublicUser.find_and_update_or_create_by_email(params[:public_user])

      @submitted_question = SubmittedQuestion.new(params[:submitted_question])
      @submitted_question.location_id = params[:location_id]
      @submitted_question.county_id = params[:county_id]
      @submitted_question.setup_categories(params[:aae_category], params[:subcategory])
      @submitted_question.status = 'submitted'
      @submitted_question.user_ip = request.remote_ip
      @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
      @submitted_question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
      @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED
      @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
      @submitted_question.external_app_id = 'www.extension.org'
      @submitted_question.public_user = @public_user

      # error check for submitted question and public user records 
      
      if !@public_user
        # create a new instance variable for public_user since it wasn't saved so the form can be repopulated
        @public_user = PublicUser.new(params[:public_user]) 
        # we know it wasn't saved, but let's see why
        if !@public_user.valid? and return_error.blank?
          return_error = "Errors occured when saving:<br />" + @public_user.errors.full_messages.join('<br />')
        end
      end
       
      if !@submitted_question.valid? and return_error.blank?
        return_error = "Errors occured when saving:<br />" + @submitted_question.errors.full_messages.join('<br />')
      end
      
      # end of error check for submitted question and public user records
      
      if !return_error.blank?
        if top_level_category = @submitted_question.top_level_category
          @sub_category_options = [""].concat(top_level_category.children.map{|sq| [sq.name, sq.id]})
          if sub_category = @submitted_question.sub_category
            @sub_category = sub_category.id
          end
        end
        flash.now[:notice] = return_error
        render nil
        return
      end

      # for easier akismet checking, set the submitter_email attribute from the associated public_user
      @submitted_question.submitter_email = @public_user.email

      # check for spam
      begin
        @submitted_question.spam = @submitted_question.spam?
      rescue Exception => ex
        logger.error "Error checking submitted question from pubsite aae form for spam via Akismet at #{Time.now.to_s}. Akismet webservice might be experiencing problems.\nError: #{ex.message}"
      end
      
      if !params[:file_attachment].blank?
        @file_attachment = FileAttachment.create(params[:file_attachment]) 
        @submitted_question.file_attachments << @file_attachment
      end

      @submitted_question.save

      session[:public_user_id] = @public_user.id

      flash[:notice] = 'Your question has been submitted and the answer will be sent to your email. Our experts try to answer within 48 hours.'
      flash[:googleanalytics] = '/ask-an-expert-question-submitted'

      if session[:return_to]
        redirect_to(session[:return_to]) 
      else
        redirect_to home_url
      end
    end
    # end of question submission POST request
  end
  
  def question_confirmation
    if request.get?
      if params[:q].blank? 
        flash[:notice] = "Please fill in the question field before submitting."
        redirect_to :action => :index
      else
        @question = params[:q].sanitize
      end
    else
      redirect_to :action => :index
    end  
  end
  
  def question
    @right_column = false
    @submitted_question = SubmittedQuestion.find_by_question_fingerprint(params[:fingerprint])
    @submitted_question_responses = @submitted_question.responses if @submitted_question
    
    if !@submitted_question
      do_404
      return
    elsif !@currentuser.nil?
      return
    elsif(!@submitted_question.show_publicly? or @submitted_question.public_user.nil?)
      render :template => 'ask/question_status'
      return
    else 
      # authorized public user check
      if(!session[:public_user_id].nil? and (public_user = PublicUser.find_by_id(session[:public_user_id])))
        # make sure - again - that this question belongs to this user
        if(@submitted_question.public_user != public_user)
          session[:public_user_id] = nil
          render :template => 'ask/question_signin'
          return
        end
      else
        render :template => 'ask/question_signin'
        return
      end
    end
    
  end
  
  def post_public_response
    if request.post? and params[:public_user_id] and params[:public_user_id].strip != '' and params[:squid] and params[:squid].strip != ''
      
      @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
      public_user = PublicUser.find_by_id(params[:public_user_id])
      
      if @submitted_question and public_user
        
        if !params[:public_user_response] or params[:public_user_response].strip == ''
          @err_msg = "The response form field is a required field to submit your response."  
          render :partial => 'public_response'
          return
        end
        
        # don't accept duplicates
        if Response.find(:first, :conditions => {:submitted_question_id => @submitted_question.id, :response => params[:public_user_response], :public_user_id => public_user.id})
          render :partial => 'public_response'
          return
        end
         
        response = Response.new(:public_responder => public_user, :submitted_question => @submitted_question, :response => params[:public_user_response], :sent => true)
        response.save
        if @submitted_question.status_state != SubmittedQuestion::STATUS_SUBMITTED
          @submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED)
          SubmittedQuestionEvent.log_public_response(@submitted_question, public_user.id)
          SubmittedQuestionEvent.log_reopen(@submitted_question, @submitted_question.assignee ? @submitted_question.assignee : nil, User.systemuser, SubmittedQuestion::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT)
          @submitted_question.assign_to(@submitted_question.assignee, User.systemuser, SubmittedQuestion::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT, true, response)  
        else
          Notification.create(:notifytype => Notification::AAE_PUBLIC_COMMENT, :user => @submitted_question.assignee, :additionaldata => {:submitted_question_id => @submitted_question.id, :response_id => response.id}) if @submitted_question.assignee
          SubmittedQuestionEvent.log_public_response(@submitted_question, public_user.id)
        end
      else
        @err_msg = "There was an error submitting your response. Please try again later."  
      end
    else
      do_404
      return
    end
    
    render :partial => 'public_response'
  end
  
  def cancel_question_edit
    if request.post? and (@submitted_question = SubmittedQuestion.find(params[:squid]))
      render :update do |page|
        page.replace_html "question_area", :partial => '/ask/question'
      end
    else
      do_404
    end
  end
  
  def authorize_public_user
    @right_column = false
    @submitted_question = SubmittedQuestion.find_by_question_fingerprint(params[:fingerprint])
    if !@submitted_question
      render :template => 'ask/question_status'
      return
    end
    
    if (params[:email_address] and params[:email_address].strip != '') and (public_user = PublicUser.find_by_email(params[:email_address])) and (request.post?)
      # make sure that this question belongs to this user
      if(@submitted_question.public_user == public_user)
        session[:public_user_id] = public_user.id
        redirect_to :action => :question, :fingerprint => params[:fingerprint]
        return
      end
    end
    
    flash.now[:warning] = "The email address you entered does not match the email used to submit the question. Please check the email address and try again."
    render :template => 'ask/question_signin'
  end
  
  def edit_question
    if request.post? and (@submitted_question = SubmittedQuestion.find_by_id(params[:squid]))

      if (response = @submitted_question.current_response) and (response.strip != '')
        flash[:warning] = "This question has already been responded to and cannot be edited."
        redirect_to :action => :question, :fingerprint => @submitted_question.question_fingerprint
        return  
      end
      
      if !params[:question] or params[:question].strip == ""
        flash[:warning] = "You must enter text into the question field."
        redirect_to :action => :question, :fingerprint => @submitted_question.question_fingerprint
        return
      end
      
      previous_question = @submitted_question.asked_question
      @submitted_question.update_attribute(:asked_question, params[:question])
      SubmittedQuestionEvent.log_event({:submitted_question => @submitted_question, :event_state => SubmittedQuestionEvent::EDIT_QUESTION, :additionaldata => @submitted_question.asked_question})
      
      # create notification if assigned
      if(!@submitted_question.assignee.nil?)
        Notification.create(:notifytype => Notification::AAE_PUBLIC_EDIT, :user => @submitted_question.assignee, :additionaldata => {:submitted_question_id => @submitted_question.id, :previous_question => previous_question})
      end
      flash[:notice] = "Your changes have been saved. Thanks for making your question better!"
      redirect_to :action => :question, :fingerprint => @submitted_question.question_fingerprint
    else
      do_404
      return
    end
  end
  
  def make_question_editable
    if request.post?
      @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
      render :layout => false
    else
      do_404
      return
    end
  end
  
  def get_aae_from_subcats
    parent_cat = Category.find_by_id(params[:category_id].strip) if params[:category_id] and params[:category_id].strip != '' 
    if parent_cat 
      @sub_category_options = [""].concat(parent_cat.children.map{|sq| [sq.name, sq.id]})
    else
      @sub_category_options = [""]
    end
    
    render :partial => 'aae_subcats', :layout => false
  end
    
end
