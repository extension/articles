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
      @status_message = "Unknown widget specified."
      return render(:template => '/widget/status', :layout => false)
    end
      
    @submitted_question = SubmittedQuestion.new
    if(!session[:account_id].nil? and @submitter = Account.find_by_id(session[:account_id]))      
      @first_name = @submitter.first_name
      @last_name = @submitter.last_name
      @email = @submitter.email
      @email_confirmation = @email
    end

    
    @host_name = request.host_with_port
    if(@widget.is_bonnie_plants_widget?)
      return render(:template => 'widget/bonnie_plants', :layout => false)
    else
      return render :layout => false
    end
  end
    
  def create_from_widget
    @widget = Widget.find_by_fingerprint(params[:widget].strip) if params[:widget]
    if(!@widget)
      @status_message = "Unknown widget specified."
      return render(:template => '/widget/status', :layout => false)
    end
      
    if request.post?
      begin
        # setup the question to be saved and fill in attributes with parameters
        # remove all whitespace in question before putting into db.
        @email = params[:email].strip
        @email_confirmation = params[:email_confirmation].strip
        @question = params[:question].strip
        @first_name = params[:first_name].strip if !params[:first_name].blank?
        @last_name = params[:last_name].strip if !params[:last_name].blank?
        
        # make sure email and confirmation email match up
        if @email != @email_confirmation
          @argument_errors = "Email address does not match the confirmation email address."
          raise ArgumentError
        end

        # name_hash just lets me update @submitter more easily
        name_hash = {}
        name_hash[:first_name] = @first_name 
        name_hash[:last_name] = @last_name
        
        if(@submitter = Account.find_by_email(@email))
          if(@submitter.first_name == 'Anonymous' or @submitter.last_name == 'Guest')
            @submitter.update_attributes(name_hash)
          end
        else
          @submitter = PublicUser.create({:email => @email}.merge(name_hash))
          if !@submitter.valid?
            @argument_errors = ("Errors occured when saving:<br />" + @submitter.errors.full_messages.join('<br />'))
            raise ArgumentError
          end
        end
        
        @submitted_question = SubmittedQuestion.new
        @submitted_question.submitter = @submitter
        @submitted_question.widget = @widget
        @submitted_question.widget_name = @widget.name
        @submitted_question.user_ip = request.remote_ip
        @submitted_question.user_agent = request.env['HTTP_USER_AGENT']
        @submitted_question.referrer = (request.env['HTTP_REFERER']) ? request.env['HTTP_REFERER'] : ''
        @submitted_question.status = SubmittedQuestion::SUBMITTED_TEXT
        @submitted_question.status_state = SubmittedQuestion::STATUS_SUBMITTED
        @submitted_question.external_app_id = 'widget'
        @submitted_question.submitter_email = @submitter.email
        @submitted_question.submitter_firstname = @submitter.first_name
        @submitted_question.submitter_lastname = @submitter.last_name
        @submitted_question.asked_question = @question 
        

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
        elsif(@widget.location_id)
          @submitted_question.location_id = @widget.location_id
          if(@widget.county_id)
            @submitted_question.county_id = @widget.county_id
          end
        end
        
        # validate submitted_question
        if !@submitted_question.valid?
          @argument_errors = ("Errors occured when saving:<br />" + @submitted_question.errors.full_messages.join('<br />'))
          raise ArgumentError
        end
            
        # handle image upload
        if !params[:image].blank?
          photo_to_upload = FileAttachment.create({:attachment => params[:image]}) 
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
          # tags
          if(@widget.enable_tags?)
            if(!params[:tag_list])
              @submitted_question.tag_myself_with_shared_tags(@widget.system_sharedtags_displaylist)
            end
          end
          flash[:notice] = "Thank You! You can expect a response emailed to the address you provided."
          return redirect_to widget_tracking_url(:widget => @widget.fingerprint), :layout => false
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        flash[:warning] = @argument_errors
        @host_name = request.host_with_port
        if(@widget.is_bonnie_plants_widget?)
          return render(:template => 'widget/bonnie_plants', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      rescue Exception => e
        flash[:notice] = 'An internal error has occured. Please check back later.'
        @host_name = request.host_with_port
        if(@widget.is_bonnie_plants_widget?)
          return render(:template => 'widget/bonnie_plants', :layout => false)
        else
          return render(:template => 'widget/index', :layout => false)
        end
      end
    else
      flash[:notice] = 'Bad request. Only POST requests are accepted.'
      return redirect_to widget_tracking_url(:widget => @widget.fingerprint), :layout => false
    end
  end
  
end