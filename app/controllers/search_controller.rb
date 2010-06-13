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
    @annotations = Annotation.paginate(:all, :order => 'url',
                                        :page => params[:page],
                                        :per_page => 25)
  end
  
  def add
    flash[:failure] = "Unable to perform requested action.  Please try again."
  end
  
  def remove
    flash[:failure] = "Unable to perform requested action.  Please try again."
  end
end