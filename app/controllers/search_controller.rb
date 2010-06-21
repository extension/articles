# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class SearchController < ApplicationController
  before_filter :login_required, :except => :index
  before_filter :check_purgatory, :except => :index
  
  layout 'search'
  
  def index
    @page_title = "Home"
  end
  
  def manage
    set_titletag('Manage CSE Links')
    if (!params[:searchterm].nil? and !params[:searchterm].empty?)
      @annotations = Annotation.patternsearch(params[:searchterm]).paginate(:all, :order => :url, :page => params[:page])
      if @annotations.nil? || @annotations.length == 0
        flash.now[:warning] = "<p>No URLs were found that matches your search term.</p>"
        @annotations = []
      end
    else
      @annotations = Annotation.paginate(:all, :order => 'url', :page => params[:page])
    end
  end
  
  def add
    flash[:failure] = "Unable to perform requested action.  Please try again."
  end
  
  def remove
    flash[:failure] = "Unable to perform requested action.  Please try again."
  end
end