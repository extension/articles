# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class WidgetController < ApplicationController  
  layout 'widgets'
  has_rakismet :only => [:create_from_widget]
  skip_before_filter :verify_authenticity_token
  
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

  # TODO: make akismet work
  def create_from_widget
    if request.post?
      
      begin
        # setup the question to be saved and fill in attributes with parameters
        create_question
        if !@submitted_question.valid?
          @argument_errors = @submitted_question.errors.full_messages.join('<br />')  
          raise ArgumentError
        end
        
        # validate akismet key and log an error if something goes wrong with connecting to 
        # akismet web service to verify the key
        #begin
        #  valid_key = has_verified_akismet_key?
        #rescue Exception => ex
        #  logger.error "Error verifying akismet key #{AppConfig.configtable['akismet_key']} at #{time.now.to_s}.\nError: #{ex.message}"
        #end
        
        # check the akismet web service to see if the submitted question is spam or not
        #if valid_key
        #  begin
        #    @submitted_question.spam = is_spam? @submitted_question.to_akismet_hash
        #  rescue Exception => exc
        #    logger.error "Error checking submitted question for spam via Akismet at #{Time.now.to_s}. Akismet webservice might be experiencing problems.\nError: #{exc.message}"
        #  end
        #else
        #  logger.error "Akismet key #{AppConfig.configtable['akismet_key']} was not validated at #{Time.now.to_s}."
        #end

        if @submitted_question.save
          render :layout => false
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        @status = '400 (argument error)'
        render :template => 'widget/status', :status => 400, :layout => false
        return
      #rescue Exception => e
      #  @status = '500 (internal error)'
      #  render :template => 'widget/status', :status => 500, :layout => false
      #  return
      end
    end
  end
  
  private
  
  def create_question
    # remove all whitespace in question before putting into db.
    params[:submitted_question].collect{|key, val| params[:submitted_question][key] = val.strip}
    widget = Widget.find_by_fingerprint(params[:id].strip) if params[:id]
    
    @submitted_question = SubmittedQuestion.new(params[:submitted_question])
    @submitted_question.widget = widget if widget
    @submitted_question.widget_name = widget.name if widget
    @submitted_question.user_ip = request.remote_ip
    @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
    @submitted_question.referrer = request.env['HTTP_REFERER']
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