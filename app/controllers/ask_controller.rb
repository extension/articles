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
    @categories = [""].concat(Category.root_categories.show_to_public.all(:order => 'name').map{|c| [c.name, c.id]})
    
    if request.get?  
      if !params[:q].blank?  
        @submitted_question = SubmittedQuestion.new(:asked_question => params[:q].sanitize)
        @right_column = false
        session[:return_to] = params[:redirect_to]
        flash.now[:googleanalytics] = '/ask-an-expert-submission-form'
    
        set_title("Ask an Expert - eXtension", "New Question")
        set_titletag("Ask an Expert - eXtension")

        if(@currentuser)
          @submitter = @currentuser
        elsif(!session[:account_id].nil?)
          @submitter = Account.find_by_id(session[:account_id]) || PublicUser.new
        else
          @submitter = PublicUser.new
        end
        
        if(!@personal[:location].blank?)
          @submitted_question.location = @personal[:location]
        end
        
        if(!@personal[:county].blank?)
          @submitted_question.county = @personal[:county]
        end
          
          
      # question was blank
      else
        flash[:notice] = "Please fill in the question field before submitting."
        redirect_to :action => :index
      end
    # Question asker submits the question (ie. POST request)
    else
      @submitted_question = SubmittedQuestion.new(params[:submitted_question])
      
      
      if(params[:submitter][:email].blank?)
        # create a new instance variable for submitter so the form can be repopulated if it doesn't already exist
        @submitter = PublicUser.new(params[:submitter]) if !@submitter
        @submitter_email_confirmation = params[:submitter_email_confirmation]
        render_aae_submission_error('Your email address cannot be blank')
        return
      end
            
      name_hash = {}
      name_hash[:first_name] = params[:submitter][:first_name].strip if !params[:submitter][:first_name].blank?
      name_hash[:last_name] = params[:submitter][:last_name].strip if !params[:submitter][:last_name].blank?
      
      if(@submitter = Account.find_by_email(params[:submitter][:email]))
        if(@submitter.first_name == 'Anonymous' or @submitter.last_name == 'Guest')
          @submitter.update_attributes(name_hash)
        end
      else
        @submitter = PublicUser.create({:email => params[:submitter][:email].strip}.merge(name_hash))
      end
      
      @submitted_question.status = 'submitted'
      @submitted_question.user_ip = request.remote_ip
      @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
      @submitted_question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
      @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED
      @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
      @submitted_question.external_app_id = 'www.extension.org'
      
      # setup categories
      if(!params[:aae_category].blank? and category = Category.find_by_id(params[:aae_category]))
        @submitted_question.categories << category
        
        if(!params[:subcategory].blank? and subcategory = Category.find_by_id_and_parent_id(params[:subcategory], category.id))
          @submitted_question.categories << subcategory
        end
      end
      
      # location and county - separate from params[:submitted_question], but probably shouldn't be
      if(params[:location_id] and location = Location.find_by_id(params[:location_id].strip.to_i))
        @submitted_question.location = location
        # change session if different
        if(!session[:location_and_county].blank?)
          if(session[:location_and_county][:location_id] != location.id)
            session[:location_and_county] = {:location_id => location.id}
          end
        else
          session[:location_and_county] = {:location_id => location.id}
        end
        if(params[:county_id] and county = County.find_by_id_and_location_id(params[:county_id].strip.to_i, location.id))
          @submitted_question.county = county
          if(!session[:location_and_county][:county_id].blank?)
            if(session[:location_and_county][:county_id] != county.id)
              session[:location_and_county][:county_id] = county.id
            end
          else
            session[:location_and_county][:county_id] = county.id
          end
        end
      end
      
      # error check for submitted question, file_attachment and public user records 
      
      if params[:submitter][:email].strip != params[:submitter_email_confirmation].strip
        # create a new instance variable for submitter so the form can be repopulated if it doesn't already exist
        @submitter = PublicUser.new(params[:submitter]) if !@submitter
        @submitter_email_confirmation = params[:submitter_email_confirmation]
        render_aae_submission_error('Your email address confirmation does not match.<br />Please make sure your email address and confirmation match up.')
        return
      end
      
      if !@submitter
        # create a new instance variable for submitter so the form can be repopulated and we can see what's gone wrong in validating
        @submitter = PublicUser.new(params[:submitter])
        # we know it wasn't saved, but let's see why
        if !@submitter.valid?
           render_aae_submission_error("Errors occured when saving:<br />" + @submitter.errors.full_messages.join('<br />'))
           return
        end
      else
        @submitted_question.submitter = @submitter
      end
       
      if !@submitted_question.valid?
        render_aae_submission_error("Errors occured when saving:<br />" + @submitted_question.errors.full_messages.join('<br />'))
        return
      end
      
      # end of error check for submitted_question, file_attachment and public user records
      
      
      # handle image upload
      
      # load up array of passed in photo parameters based on how many are allowed
      photo_array = get_photo_array
      # create each file upload and check for errors
      photo_array.each do |photo_params|
        photo_to_upload = FileAttachment.create(photo_params) 
        if !photo_to_upload.valid?
          render_aae_submission_error("Errors occured when uploading one of your images:<br />" + photo_to_upload.errors.full_messages.join('<br />'))        
          return
        else
          @submitted_question.file_attachments << photo_to_upload
        end   
      end
      
      # end of handling image upload
      
      
      # for easier akismet checking, set the submitter_email attribute from the associated submitter
      @submitted_question.submitter_email = @submitter.email

      # check for spam
      begin
        @submitted_question.spam = @submitted_question.spam?
      rescue Exception => ex
        logger.error "Error checking submitted question from pubsite aae form for spam via Akismet at #{Time.now.to_s}. Akismet webservice might be experiencing problems.\nError: #{ex.message}"
      end
      
      @submitted_question.save
      # tag it, based on the category/subcategory (if present)
      if(category)
        tags = [category.name]
        if(subcategory)
          tags << "#{category.name}:#{subcategory.name}"
        end
        @submitted_question.replace_tags_with_and_cache(tags, User.systemuserid, Tagging::SHARED)
      end
        
      session[:account_id] = @submitter.id
      flash[:notice] = 'Your question has been submitted. Our experts try to answer within 48 hours and we will notify you with an email message when they do.'
      flash[:googleanalytics] = '/ask-an-expert-question-submitted'
        
      if session[:return_to]
        redirect_to(session[:return_to]) 
      else
        redirect_to home_url
      end
    end
    # end of question submission POST request
  end
  
  def add_images
    if request.post?
      
      if params[:squid].blank? or !@submitted_question = SubmittedQuestion.find(params[:squid])
        do_404
        return
      end
      
      # load up array of passed in photo parameters based on how many are allowed
      photo_array = get_photo_array
      # create each file upload and check for errors
      photo_array.each do |photo_params|
        photo_to_upload = FileAttachment.create(photo_params) 
        if !photo_to_upload.valid?
          flash[:notice] = "Errors occured when uploading one of your images:<br />" + photo_to_upload.errors.full_messages.join('<br />')        
          break
        else
          @submitted_question.file_attachments << photo_to_upload
        end   
      end
      flash[:notice] = "Photos saved successfully!" if flash[:notice].blank?
      redirect_to :action => :question, :fingerprint => @submitted_question.question_fingerprint
    else
      do_404
      return
    end
  end
  
  def delete_response_image
    if request.post?
        # make sure everything was passed in correctly and that the valid question submitter is making this request
        return if (params[:id].blank? or params[:response_id].blank?)
        return if !response = Response.find(params[:response_id]) 
        return if !((response.submitted_question.submitter.id == session[:account_id]) or (@currentuser.email == response.submitted_question.submitter_email))
        return if !file_attachment = FileAttachment.find(params[:id])
        
        FileAttachment.destroy(file_attachment.id) 
        
        render :update do |page|
          page.replace_html "response_image_div#{response.id}", :partial => 'response_images', :locals => { :response => response, :submitted_question => response.submitted_question }
        end
    else
      do_404
      return
    end
  end
  
  def delete_sq_image
    if request.post?
      # make sure everything was passed in correctly and that the valid question submitter is making this request
      return if (params[:id].blank? or params[:squid].blank?)
      return if !@submitted_question = SubmittedQuestion.find(params[:squid])
      return if !((@submitted_question.submitter.id == session[:account_id]) or (@currentuser.email == @submitted_question.submitter_email))
      return if !file_attachment = FileAttachment.find(params[:id]) 
       
      FileAttachment.destroy(file_attachment.id) 
          
      render :update do |page|
        page.replace_html "aae_image_div", :partial => 'aae_images'
      end
    else
      do_404
      return
    end
  end
  
  def question_confirmation
    flash.now[:googleanalytics] = '/ask-an-expert-search-results'
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
    elsif(!@submitted_question.show_publicly? or @submitted_question.submitter.nil?)
      render :template => 'ask/question_status'
      return
    else 
      # authorized public user check
      if(!session[:account_id].nil? and (submitter = Account.find_by_id(session[:account_id])))
        # make sure - again - that this question belongs to this user
        if(@submitted_question.submitter != submitter)
          session[:account_id] = nil
          render :template => 'ask/question_signin'
          return
        end
      else
        render :template => 'ask/question_signin'
        return
      end
    end
    
  end
  
  def post_submitter_response
    if request.post? and params[:submitter_id] and params[:submitter_id].strip != '' and params[:squid] and params[:squid].strip != ''
      
      @submitted_question = SubmittedQuestion.find_by_id(params[:squid])
      submitter = Account.find_by_id(params[:submitter_id])
      
      if @submitted_question and submitter
        
        if params[:submitter_response].blank?
          render_aae_response_error("The response form field is a required field to submit your response.") 
          return
        end
        
        # don't accept duplicates
        if Response.find(:first, :conditions => {:submitted_question_id => @submitted_question.id, :response => params[:submitter_response], :submitter_id => submitter.id})
          render_aae_response_error("We have already received your response. Thank you!") 
          return
        end
        
        response = Response.new(:submitter => submitter, :submitted_question => @submitted_question, :response => params[:submitter_response], :sent => true)
        
        # handle image upload

        # load up array of passed in photo parameters based on how many are allowed
        photo_array = get_photo_array
        # create each file upload and check for errors
        photo_array.each do |photo_params|
          photo_to_upload = FileAttachment.create(photo_params) 
          if !photo_to_upload.valid?
            render_aae_response_error("Errors occured when uploading one of your images:<br />" + photo_to_upload.errors.full_messages.join('<br />'))        
            return
          else
            response.file_attachments << photo_to_upload
          end   
        end

        # end of handling image upload
        
        # save it baby
        response.save
        
        if @submitted_question.status_state != SubmittedQuestion::STATUS_SUBMITTED
          @submitted_question.update_attributes(:status => SubmittedQuestion::SUBMITTED_TEXT, :status_state => SubmittedQuestion::STATUS_SUBMITTED)
          SubmittedQuestionEvent.log_public_response(@submitted_question, submitter.id)
          SubmittedQuestionEvent.log_reopen(@submitted_question, @submitted_question.assignee ? @submitted_question.assignee : nil, User.systemuser, SubmittedQuestion::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT)
          @submitted_question.assign_to(@submitted_question.assignee, User.systemuser, SubmittedQuestion::PUBLIC_RESPONSE_REASSIGNMENT_COMMENT, true, response)  
        else
          Notification.create(:notifytype => Notification::AAE_PUBLIC_COMMENT, :account => @submitted_question.assignee, :additionaldata => {:submitted_question_id => @submitted_question.id, :response_id => response.id}) if @submitted_question.assignee
          SubmittedQuestionEvent.log_public_response(@submitted_question, submitter.id)
        end
      else
        render_aae_response_error("There was an error submitting your response. Please try again.")
        return
      end
    else
      do_404
      return
    end
    
    flash[:notice] = "Response has been successfully submitted!"
    redirect_to :action => :question, :fingerprint => @submitted_question.question_fingerprint   
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
  
  def authorize_submitter
    @right_column = false
    @submitted_question = SubmittedQuestion.find_by_question_fingerprint(params[:fingerprint])
    if !@submitted_question
      render :template => 'ask/question_status'
      return
    end
    
    if (params[:email_address] and params[:email_address].strip != '') and (submitter = Account.find_by_email(params[:email_address].strip.downcase)) and (request.post?)
      # make sure that this question belongs to this user
      if(@submitted_question.submitter == submitter)
        session[:account_id] = submitter.id
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
        Notification.create(:notifytype => Notification::AAE_PUBLIC_EDIT, :account => @submitted_question.assignee, :additionaldata => {:submitted_question_id => @submitted_question.id, :previous_question => previous_question})
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
  
  def get_aae_form_subcats
    parent_cat = Category.find_by_id(params[:category_id].strip) if params[:category_id] and params[:category_id].strip != '' 
    if parent_cat 
      @sub_category_options = [""].concat(parent_cat.children.show_to_public.all(:order => 'name').map{|sq| [sq.name, sq.id]})
    else
      @sub_category_options = [""]
    end
    
    render :partial => 'aae_subcats', :layout => false
  end
  
  private
  
  def render_aae_response_error(return_error)
    if !return_error.blank?
      flash[:notice] = return_error
      redirect_to :action => :question, :fingerprint => @submitted_question.question_fingerprint
      return
    end
  end
  
  def render_aae_submission_error(return_error)
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
  end
  
  def get_photo_array
    photo_array = Array.new
    (1..FileAttachment::MAX_AAE_UPLOADS).each do |image_counter| 
      if !params["file_attachment#{image_counter}"].blank?
        photo_array << params["file_attachment#{image_counter}"]
      end
    end
    return photo_array
  end
    
end
