# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
# 
#  see LICENSE file

class Widgets::HomeController < ApplicationController
  layout 'frontporch'
  before_filter :signin_optional

  def index
  end
  
end