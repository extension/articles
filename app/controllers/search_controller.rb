# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

include ActionView::Helpers::UrlHelper
include ActionController::UrlWriter
include ActionView::Helpers::TagHelper

class SearchController < ApplicationController
  before_filter :signin_optional, :only => :index
  before_filter :signin_required, :except => :index
  layout 'search'
  
  def index
    @page_title = "Home"
  end
  
  def manage
    @page_title = "Manage Links"
    set_title('Manage CSE Links')
    if (!params[:searchterm].nil? and !params[:searchterm].empty?)
      @annotations = Annotation.patternsearch(params[:searchterm]).paginate(:all, :order => :url, :page => params[:page])
      if @annotations.nil? || @annotations.length == 0
        flash.now[:warning] = "No URLs were found that matches your search term."
      end
    else
      @annotations = Annotation.paginate(:all, :order => 'added_at DESC', :page => params[:page])
    end
  end
  
  def manage_activity
    @page_title = "CSE Link Management Activity"
    @events = AnnotationEvent.paginate(:all, :joins => :person, :order => 'created_at DESC', :page => params[:page])
  end
  
  def manage_event
    @page_title = "CSE Link Management Event"
    @event = AnnotationEvent.find_by_id(params[:id])
  end
  
  def add
    if (!params[:url].nil? and !params[:url].empty?)
      annote = Annotation.new
      result = annote.add(params[:url], current_person)
      
      if result[:success]
        flash[:success] = "#{annote.url} has been added to search."
      else
        flash[:failure] = "Unable to add #{params[:url]} - #{result[:msg]}"
      end
      
    else
      flash[:warning] = "No valid url provided."
    end
    
    redirect_to(:action => :manage, :searchterm => params[:searchterm])
  end
  
  def remove
    if (!params[:id].nil? and !params[:id].empty?)
      goner = Annotation.find_by_id(params[:id])
      
      if goner
        result = goner.remove(current_person)
      else
        result = {:success => false, :msg => "URL ID not found"}
      end
      
      if result[:success]
        flash[:success] = "#{goner.url} has been removed from search. "
        flash[:success] << link_to("UNDO", url_for(:action => :add, :url => goner.url, :searchterm => params[:searchterm]), :class => "bigbutton blue")
      else
        if goner
          flash[:failure] = "Unable to remove #{goner.url} - #{result[:msg]}"
        else
          flash[:failure] = "Unable to remove URL - #{result[:msg]}"
        end
      end
    else
      flash[:warning] = "No valid id provided."
    end
    
    redirect_to(:action => :manage, :searchterm => params[:searchterm])
  end
end