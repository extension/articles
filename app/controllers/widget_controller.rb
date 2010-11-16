# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'rest_client'
require 'json/pure'

class WidgetController < ApplicationController  
  layout 'widgets'
  has_rakismet :only => [:create_from_widget]
  ssl_allowed :index, :create_from_widget


  # ask widget pulled from remote iframe
  def index
    filteredparams = ParamsFilter.new([:widget],params)
    @widget = filteredparams.widget
    if !@widget.blank?
      if !@widget.active?
        @status_message = "This widget has been disabled."
        return render(:template => '/widget/status', :layout => false)
      end
    else
      @status_message = "Unknown widget."
      return render(:template => '/widget/status', :layout => false)
    end
      
    @submitted_question = SubmittedQuestion.new
    @submitter = PublicUser.new
    @host_name = request.host_with_port
    render :layout => false
  end
  
  # api-enabled ask widget for iframe
  def api_widget_index
    if params[:location]
      @location = Location.find_by_abbreviation(params[:location].strip)
      if params[:county] and @location
        @county = County.find_by_name_and_location_id(params[:county].strip, @location.id)
      end 
    end
    
    @fingerprint = params[:id]
    @host_name = request.host_with_port
    render :layout => false
  end
  
  def create_from_widget
    if request.post?
      begin
        # setup the question to be saved and fill in attributes with parameters
        create_question
        
        if !@submitter
          # create a new instance variable for submitter so the form can be repopulated and we can see what's gone wrong in validating
          @submitter = PublicUser.new(params[:submitter])
          # we know it wasn't saved, but let's see why
          if !@submitter.valid?
            @argument_errors = ("Errors occured when saving:<br />" + @submitter.errors.full_messages.join('<br />'))
            raise ArgumentError
          end
        end
        
        # validate submitted_question
        if !@submitted_question.valid?
          @argument_errors = ("Errors occured when saving:<br />" + @submitted_question.errors.full_messages.join('<br />'))
          raise ArgumentError
        end
        
        # make sure email and confirmation email match up
        if params[:submitted_question][:submitter_email] != params[:submitter_email_confirmation]
          @argument_errors = "Email address does not match the confirmation email address."
          raise ArgumentError
        end
    
        # handle image upload
        if !params[:file_attachment].blank?
          photo_to_upload = FileAttachment.create(params[:file_attachment]) 
          if !photo_to_upload.valid?
            @argument_errors = "Errors occured when uploading your image:<br />" + photo_to_upload.errors.full_messages.join('<br />')        
            raise ArgumentError
          else
            @submitted_question.file_attachments << photo_to_upload
          end   
        end
        # end of handling image upload
        
        begin
          @submitted_question.spam = @submitted_question.spam? 
        rescue Exception => exc
          logger.error "Error checking submitted question from widget for spam via Akismet at #{Time.now.to_s}. Akismet webservice might be experiencing problems.\nError: #{exc.message}"
        end
        
        if @submitted_question.save
          session[:account_id] = @submitter.id
          flash[:notice] = "Thank You! You can expect a response emailed to the address you provided."
          redirect_to widget_url(:id => params[:id]), :layout => false
          return
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        flash[:warning] = @argument_errors
        @fingerprint = params[:id]
        @host_name = request.host_with_port
        render :template => 'widget/index', :layout => false
        return
      rescue Exception => e
        flash[:notice] = 'An internal error has occured. Please check back later.'
        @fingerprint = params[:id]
        @host_name = request.host_with_port
        render :template => 'widget/index', :layout => false
        return
      end
    else
      flash[:notice] = 'Bad request. Only POST requests are accepted.'
      redirect_to widget_url, :layout => false
      return
    end
  end
  
  ### BONNIE PLANTS STUFF ###

  ## This is only for use for a custom widget for the Bonnie Plants website
  ## This is intended for short-term use until we get custom widgets 
  ## up and operational.
  def bonnie_plants
    if params[:id].blank? or !Widget.find_by_fingerprint_and_name(params[:id].strip, 'Bonnie Plants')
      @status_message = "There are configuration problems with this widget (invalid widget ID). Please try again later."
      return render :template => 'widget/api_widget_status', :layout => false 
    end
    
    @submitted_question = SubmittedQuestion.new
    @submitter = PublicUser.new
    @fingerprint = params[:id]
    @host_name = request.host_with_port
    render :layout => false
  end
  
  ## create question from Bonnie Plants custom form/widget
  def create_from_bonnie_plants
    if request.post?
      @email = params[:email]
      @email_confirmation = params[:email_confirmation]
      @question = params[:question]
      @first_name = params[:first_name]
      @last_name = params[:last_name]
        
      if !params[:location_id].blank?
        @location = Location.find(params[:location_id].strip)
      end
      
      if @location and (!params[:county_id].blank?)
        @county = County.find_by_id_and_location_id(params[:county_id].strip.to_i, @location.id)
      end
        
      if @email.blank? or @email_confirmation.blank? or @question.blank?
        render_bonnie_plants_widget_error("Please fill in all required fields.")
        return
      end  
      
      if @email.strip != @email_confirmation.strip
        render_bonnie_plants_widget_error("The email confirmation does not match the email address entered. Please make sure they match.")
        return
      end
      
      params_hash = {:question => @question,
                    :email => @email,
                    :widget_id => params[:id],
                    :first_name => @first_name,
                    :last_name => @last_name,
                    :image => params[:image],
                    :location => @location ? @location.abbreviation : nil,
                    :county => @county ? @county.name : nil,
                    :accept => :json,
                    :multipart => true}
      
      response = RestClient.post(url_for(:controller => 'api/aae', :action => :ask, :format => :json), params_hash) 
      case response.code
      when 200
        flash[:notice] = "Thank You! You can expect a response emailed to the address you provided."
        redirect_to :action => :bonnie_plants, :id => params[:id]
        return
      when 400
        render_bonnie_plants_widget_error("A configuration error has prevented your question from submitting. Please try again later.")
        return
      when 403
        response_hash = JSON.parse response.body
        render_bonnie_plants_widget_error(response_hash['error'])
        return
      else
        render_bonnie_plants_widget_error('An internal error has occured. Please check back later.')
        return
      end    
    # if GET request occured for this controller method  
    else
      @status_message = "Only POST requests from a AaE form are accepted."
      return render :template => 'widget/api_widget_status', :layout => false
    end
  end

  ### END BONNIE PLANTS STUFF ###
  
  def create_from_widget_using_api
    if request.post?  
      uri = URI.parse(url_for(:controller => 'api/aae', :action => :ask, :format => :json))
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.post(uri.path, "question=#{params[:question]}&email=#{params[:email]}&email_confirmation=#{params[:email_confirmation]}&widget_id=#{params[:id]}&type=widget")
      
      case response
      when Net::HTTPOK
        return render :template => 'widget/create_from_widget', :layout => false
      when Net::HTTPBadRequest
        @status_message = "A configuration error has prevented your question from submitting. Please try again later."
        return render :template => 'widget/api_widget_status', :layout => false
      when Net::HTTPForbidden
        response_hash = JSON.parse response.body
        @status_message = response_hash['error']
        return render :template => 'widget/api_widget_status', :layout => false  
      else
        @status_message = "We are currently experiencing technical difficulties with the system. Please try again later."
        return render :template => 'widget/api_widget_status', :layout => false  
      end
        
    end
  end
  
  private
  
  def create_question
    # remove all whitespace in question before putting into db.
    params[:submitted_question].collect{|key, val| params[:submitted_question][key] = val.strip}
    widget = Widget.find_by_fingerprint(params[:id].strip) if params[:id]
    
    @submitted_question = SubmittedQuestion.new(params[:submitted_question])
    if(!(@submitter = Account.find_by_email(@submitted_question.submitter_email)))
      @submitter = PublicUser.create({:email => @submitted_question.submitter_email})
    end
    @submitted_question.submitter = @submitter
    @submitted_question.widget = widget if widget
    @submitted_question.widget_name = widget.name if widget
    @submitted_question.user_ip = request.remote_ip
    @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
    @submitted_question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
    @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
    @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED
    @submitted_question.external_app_id = 'widget'
    
    if(!@submitted_question.location_id and widget.location_id)
      @submitted_question.location_id = widget.location_id
    end

    if(!@submitted_question.county_id and widget.county_id)
      @submitted_question.county_id = widget.county_id
    end
  end
  
  ### BONNIE PLANTS STUFF ###
  def render_bonnie_plants_widget_error(status_message)
    flash.now[:warning] = status_message
    @fingerprint = params[:id]
    @host_name = request.host_with_port
    
    @submitted_question = SubmittedQuestion.new
    @submitted_question.location = @location if @location
    @submitted_question.county = @county if @county
    
    return render :template => 'widget/bonnie_plants', :layout => false
  end
  ### END BONNIE PLANTS STUFF ### 
end