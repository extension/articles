# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::HomeController < ApplicationController
  layout 'widgetshome'
  before_filter :login_optional

  def index
    if(@app_location_for_display == 'production')
      return redirect_to(widgets_aae_url)
    end
  end
  
end