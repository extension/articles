# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::AaeController < ApplicationController
  before_filter :login_required, :except => [:index, :about, :documentation, :who, :login_redirect]
  before_filter :check_purgatory, :except => [:index, :about, :documentation, :who, :login_redirect]
  before_filter :login_optional, :only => [:index, :about, :documentation, :who]
  
  layout 'widgetshome'
  
  def redirector
    if params[:redirectparam] and self.respond_to?(params[:redirectparam])
      return redirect_to(:action => params[:redirectparam])
    else
      return redirect_to(:action => :index)
    end
  end
  
  def index
  end
  
  def who 
  end

  def documentation
  end

  def about 
  end
  
  def login_redirect
    session[:return_to] = params[:return_back]
    redirect_to :controller => 'people/account', :action => :login
  end
  
  def list
    if params[:id] and params[:id] == 'inactive'
      @widgets = Widget.get_all_with_assignee_count(:include => :user, :conditions => 'widgets.active = false')
      @selected_tab = :inactive
    else
      @selected_tab = :all
      @widgets = Widget.get_all_with_assignee_count(:include => :user, :conditions => 'widgets.active = true')
    end
  end
  
  def view
    if !(params[:id] and @widget = Widget.find(params[:id]))
      flash[:failure] = "You must specify a valid widget"
      redirect_to :action => :index
    else
      @widget_iframe_code = @widget.get_iframe_code
      @widget_assignees = @widget.assignees
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
      render :template => '/widgets/aae/new'
      return
    end

    @widget.set_fingerprint(@currentuser)
    @widget_url = url_for(:controller => '/widget', :location => location_str, :county => county_str, :id => @widget.fingerprint, :only_path => false)  
    @widget.widget_url = @widget_url

    @currentuser.widgets << @widget
  end

  def get_widgets
    if params[:id] and params[:id] == 'inactive'
      @widgets = Widget.get_all_with_assignee_count(:include => :user, :conditions => "widgets.name LIKE '#{params[:widget_name]}%' AND widgets.active = false")
    else
      @widgets = Widget.get_all_with_assignee_count(:include => :user, :conditions => "widgets.name LIKE '#{params[:widget_name]}%' AND widgets.active = true")
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
  
end