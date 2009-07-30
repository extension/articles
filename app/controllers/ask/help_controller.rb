# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class HelpController < ApplicationController
  
  def tags
  end
  
  def index
    @page = params[:id]
    if !@page.nil?
      @feed_text = HelpFeed.fetch_feed(@page)
    else
      @feed_text = ""
    end
  end
end