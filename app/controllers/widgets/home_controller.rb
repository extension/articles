# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Widgets::HomeController < ApplicationController
  layout 'widgets'
  before_filter :login_optional

  def index
    return redirect_to(widgets_aae_url)
  end
  
end