# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Api::AaeController < ApplicationController

  has_rakismet :only => [:ask]


  def ask
    if request.post?
      begin 
        if !params[:question] or !params[:email] 
          argument_errors = "Required parameters were not passed. Please check API documentation for correct parameters."
          send_json_error(argument_errors, 400)
        end
          
        if params[:question].blank? or params[:email].blank?
          param_entry_errors = "You must fill in all fields to submit your question."
          send_json_error(param_entry_errors, 403)
        end
        
        ############### setup the question to be saved and fill in attributes with parameters ###############
        widget = Widget.find_by_fingerprint(params[:widget_id].strip) if params[:widget_id]

        @public_user = PublicUser.find_and_update_or_create_by_email({:email => params[:email].strip})
        @submitted_question = SubmittedQuestion.new(:asked_question => params[:question].strip, :submitter_email => params[:email].strip)
        @submitted_question.public_user = @public_user
        @submitted_question.widget = widget if widget
        @submitted_question.widget_name = widget.name if widget
        @submitted_question.user_ip = request.remote_ip
        @submitted_question.user_agent = (request.env['HTTP_USER_AGENT']) ? request.env['HTTP_USER_AGENT'] : ''
        @submitted_question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
        @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
        @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED

        if params[:type]
          if params[:type] == 'pubsite'
            @submitted_question.external_app_id = 'www.extension.org'
          else
            @submitted_question.external_app_id = 'widget'
          end
        else
          @submitted_question.external_app_id = 'widget'
        end

        # check to see if question has location associated with it
        location = params[:location].strip if params[:location] and params[:location].strip != ''

        if location
          location = Location.find_by_abbreviation_or_name(location)
          @submitted_question.location = location if location
        end

        # check to see if question has county and said location associated with it
        county = params[:county].strip if params[:county] and params[:county].strip != ''
        county = location.get_associated_county(county) if location

        if county and location
          @submitted_question.county = county 
        end
        ############### end of setting up question object ###############
        
        if(!@submitted_question.valid? or !@public_user.valid?)
          active_record_errors = (@submitted_question.errors.full_messages + @public_user.errors.full_messages ).join('<br />')
          raise ActiveRecordError
        end
        
        begin
          @submitted_question.spam = @submitted_question.spam? 
        rescue Exception => exc
          logger.error "Error checking submitted question from widget for spam via Akismet at #{Time.now.to_s}. Akismet webservice might be experiencing problems.\nError: #{exc.message}"
        end
       
        if @submitted_question.save
          respond_to do |format|
            format.json { return render :text => {:completed => true, :submitted_question_url => "aae/question/#{@submitted_question.id}"}.to_json, :layout => false }
          end
        else
          active_record_errors = "Question not successfully saved."
          raise ActiveRecordError
        end
      
      rescue ActiveRecordError 
        send_json_error(active_record_errors, 500)
      rescue Exception
        send_json_error('Application/Server Error', 500)
      end
      
    # didn't do a POST
    else  
      send_json_error('Only POST requests are accepted', 400)
    end
  end
  
  private
  
  # to be used to generate json formatted error responses on error 
  def send_json_error(error_msg, status_code)
    return_hash = {:error => error_msg, :request => url_for(:only_path => false)}
    
    respond_to do |format|
      format.json {return render :text => return_hash.to_json, :status => status_code, :layout => false}
    end
  end

end