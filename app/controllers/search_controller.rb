# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'gdata'
require 'lib/gdata_cse'

class SearchController < ApplicationController
  before_filter :login_required, :except => :index
  before_filter :check_purgatory, :except => :index
  
  layout 'search'
  
  def index
    @page_title = "Home"
  end
  
  def manage
    set_titletag('Manage CSE Links')
    client = GData::Client::Cse.new
    client.clientlogin(AppConfig.configtable['cse_uid'],
                       AppConfig.configtable['cse_secret'])
    @domains = client.getAnnotations
  end
  
  def add
    flash[:failure] = "Unable to perform requested action.  Please try again."
  end
  
  def remove
    flash[:failure] = "Unable to perform requested action.  Please try again."
  end
end