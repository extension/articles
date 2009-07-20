# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Ask::WidgetsController < ApplicationController
  
  before_filter :login_required, :except => [:create_from_widget, :widget, :index, :about, :documentation, :who]
  before_filter :login_optional, :only => [:index, :about, :documentation, :who]
  layout 'widgets'
  
  def list
    if params[:id] and params[:id] == 'inactive'
      @widgets = Widget.inactive
      @selected_tab = :inactive
    else
      @selected_tab = :all
      @widgets = Widget.active
    end
  end
  
  def index
    
  end
  
  def admin
  end
  
  def who 
  end
  
  def documentation
  end
  
  def about 
  end
  
  def view
    if !(params[:id] and @widget = Widget.find(params[:id]))
      flash[:failure] = "You must specify a valid widget"
      redirect_to :action => :index
    else
      @widget_iframe_code = @widget.get_iframe_code
    end
  end
  
  # created new named widget form
  def new
    @location_options = get_location_options
  end
  
  # generates the iframe code for users to paste into their websites 
  # that pulls the widget code from this app with provided location and county
  def generate_widget_code
    if params[:location_id]
      location = Location.find_by_id(params[:location_id].strip.to_i)
      if params[:county_id] and location
        county = County.find_by_id_and_location_id(params[:county_id].strip.to_i, location.id)
      end
    end
    
    (location) ? location_str = location.abbreviation : location_str = nil
    (county and location) ? county_str = county.name : county_str = nil
    
    @widget = Widget.new(params[:widget])
    
    if !@widget.valid?
      @location_options = get_location_options
      render :template => '/ask/widgets/new'
      return
    end
    
    @widget.set_fingerprint(@currentuser)
    @widget_url = url_for(:controller => 'ask/widgets', :action => :widget, :location => location_str, :county => county_str, :id => @widget.fingerprint, :only_path => false)  
    @widget.widget_url = @widget_url
    @widget.author = @currentuser.login
    
    @currentuser.widgets << @widget
  end
  
  def get_widgets
    if params[:id] and params[:id] == 'inactive'
      @widgets = Widget.byname(params[:widget_name]).inactive
    else
      @widgets = Widget.byname(params[:widget_name]).active
    end
    render :partial => "widget_list", :layout => false
  end
  
  def toggle_activation
    if request.post?
      if params[:widget_id]
        @widget = Widget.find(params[:widget_id])
        @widget.update_attributes(:active => !@widget.active?)
        event = @widget.active? ? WidgetEvent::ACTIVATED : WidgetEvent::DEACTIVATED
        
        WidgetEvent.log_event(@widget.id, @currentuser.id, event)
        
        render :update do |page|
          page.visual_effect :highlight, @widget.name
          page.replace_html :widget_active, @widget.active? ? "Active" : "Inactive"
          page.replace_html :history, :partial => 'widget_history'
        end        
      end
    else
      do_404
    end
  end
  
  # ask widget pulled from remote iframe
  def widget
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

  def widget_assignees
    @widget = Widget.find(params[:id])
    if !@widget
      flash[:notice] = "The widget you specified does not exist."
      redirect_to :controller => :account, :action => :widget_preferences
      return
    end
    @widget_assignees = @widget.assignees
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
          if @submitted_question.assignee
            if(AppConfig.configtable['send_aae_emails'])
              #AskMailer.deliver_assigned(@submitted_question, url_for(:controller => 'ask/expert', :action => 'question', :id => @submitted_question.id), request.host)
            end
          end
          render :layout => false
        else
          raise InternalError
        end
      
      rescue ArgumentError => ae
        @status = '400 (argument error)'
        render :template => 'ask/widgets/status', :status => 400, :layout => false
        return
      #rescue Exception => e
      #  @status = '500 (internal error)'
      #  render :template => 'ask/expert/status', :status => 500, :layout => false
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