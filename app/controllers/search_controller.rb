# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class SearchController < ApplicationController
  before_filter :login_optional, :only => :index
  before_filter :login_required, :except => :index
  before_filter :check_purgatory, :except => :index
  layout 'search'
  
  def index
    @page_title = "Home"
  end
  
  def manage
    @page_title = "Manage Links"
    set_titletag('Manage CSE Links')
    if (!params[:searchterm].nil? and !params[:searchterm].empty?)
      @annotations = Annotation.patternsearch(params[:searchterm]).paginate(:all, :order => :url, :page => params[:page])
      if @annotations.nil? || @annotations.length == 0
        flash.now[:warning] = "<p>No URLs were found that matches your search term.</p>"
      end
    else
      @annotations = Annotation.paginate(:all, :order => 'url', :page => params[:page])
    end
  end
  
  def add
    if (!params[:url].nil? and !params[:url].empty?)
      annote = Annotation.new
      result = annote.add(params[:url])
      
      if result[:success]
        flash[:success] = "#{annote.url} has been added to search."
      else
        flash[:failure] = "Unable to add #{params[:url]} - #{result[:msg]}"
      end
      
    else
      flash[:notice] = "No valid url provided."
    end
    
    redirect_to(:action => :manage)
  end
  
  def remove
    if (!params[:id].nil? and !params[:id].empty?)
      goner = Annotation.find(params[:id])
      result = goner.remove
      if result[:success]
        flash[:success] = "#{goner.url} has been removed from search"
      else
        flash[:failure] = "Unable to remove #{goner.url} - #{result[:msg]}"
      end
    else
      flash[:notice] = "No valid id provided."
    end
    
    redirect_to(:action => :manage)
  end
end