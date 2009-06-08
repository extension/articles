# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Ask::WidgetsController < ApplicationController
  
  def index
    if params[:id] and params[:id] == 'inactive'
      @widgets = Widget.inactive
    else
      @widgets = Widget.active
    end
  end
  
  def admin
    if params[:id] and @widget = Widget.find(params[:id])
      @widget_iframe_code = @widget.get_iframe_code
    else
      flash[:failure] = "You must specify a valid widget"
      redirect_to :action => :index
    end
    render :action => :view
  end
  
  def view
    if !(params[:id] and @widget = Widget.find(params[:id]))
      flash[:failure] = "You must specify a valid widget"
      redirect_to :action => :index
    end
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
        # ToDo: change to current user, just putting in an id for now
        WidgetEvent.log_event(@widget.id, 12, event)
        
        render :update do |page|
          page.visual_effect :highlight, @widget.name
          page.replace_html :widget_active, @widget.active? ? "yes" : "no"
          page.replace_html :history, :partial => 'widget_history'
        end        
      end
    else
      do_404
    end
  end
  
  
end