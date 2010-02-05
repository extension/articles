# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'net/http'
require 'uri'

class WidgetController < ApplicationController  
  layout 'widgets'
  has_rakismet :only => [:create_from_widget]

  # ask widget pulled from remote iframe
  def index
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
        if !params[:submitted_question][:asked_question] or params[:submitted_question][:asked_question].strip == '' or !params[:submitted_question][:submitter_email] or params[:submitted_question][:submitter_email].strip == ''
          @argument_errors = "You must fill in all fields to submit your question."
          raise ArgumentError
        end
        
        if params[:submitted_question][:submitter_email] != params[:submitter_email_confirmation]
          @argument_errors = "Email address does not match the confirmation email address."
          raise ArgumentError
        end
        
        # setup the question to be saved and fill in attributes with parameters
        create_question
        
        if(!@submitted_question.valid? or !@public_user.valid?)
          @argument_errors = (@submitted_question.errors.full_messages + @public_user.errors.full_messages ).join('<br />')
          raise ArgumentError
        end
        
        begin
          @submitted_question.spam = @submitted_question.spam? 
        rescue Exception => exc
          logger.error "Error checking submitted question from widget for spam via Akismet at #{Time.now.to_s}. Akismet webservice might be experiencing problems.\nError: #{exc.message}"
        end
        
        if @submitted_question.save
          session[:public_user_id] = @public_user.id
          render :layout => false
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        @status = '400 (argument error)'
        render :template => 'widget/status', :status => 400, :layout => false
        return
      rescue Exception => e
        @status = '500 (internal error)'
        render :template => 'widget/status', :status => 500, :layout => false
        return
      end
    end
  end
  
  def create_from_widget_using_api
    if request.post?  
      uri = URI.parse(url_for(:controller => 'api/aae', :action => :ask, :format => :json))
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.post(uri.path, "aae_question=#{params[:aae_question]}&aae_email=#{params[:aae_email]}&aae_email_confirmation=#{params[:aae_email_confirmation]}&widget_id=#{params[:id]}&type=widget")
      
      case response.class
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
        @status_message = "We are currently experiencing technical difficulties with the system. Please try again later. CLASS:#{response.class.name}"
        return render :template => 'widget/api_widget_status', :layout => false  
      end
        
    end
  end
  
  private
  
  def create_question
    # remove all whitespace in question before putting into db.
    params[:submitted_question].collect{|key, val| params[:submitted_question][key] = val.strip}
    widget = Widget.find_by_fingerprint(params[:id].strip) if params[:id]
    
    @public_user = PublicUser.find_and_update_or_create_by_email({:email => params[:submitted_question][:submitter_email]})
    @submitted_question = SubmittedQuestion.new(params[:submitted_question])
    @submitted_question.public_user = @public_user
    @submitted_question.widget = widget if widget
    @submitted_question.widget_name = widget.name if widget
    @submitted_question.user_ip = request.remote_ip
    @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
    @submitted_question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
    @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
    @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED
    @submitted_question.external_app_id = 'widget'
    
    
    # check to see if question has location associated with it
    incoming_location = params[:location].strip if params[:location] and params[:location].strip != '' and params[:location].strip != Location::ALL
    
    if incoming_location
      location = Location.find_by_fipsid(incoming_location.to_i)
      @submitted_question.location = location if location
    end
    
    # check to see if question has county and said location associated with it
    incoming_county = params[:county].strip if params[:county] and params[:county].strip != '' and params[:county].strip != County::ALL
    
    if incoming_county and location
      county = County.find_by_fipsid_and_location_id(incoming_county.to_i, location.id)
      @submitted_question.county = county if county
    end
  end
   
end