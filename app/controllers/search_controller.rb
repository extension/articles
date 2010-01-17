# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class SearchController < ApplicationController
  session :off
  layout 'search'
  
  def index
  	@home = true unless params[:q]
		@page_title = "Home"
  end
	
	def about
		@page_title = "About"
	end
end