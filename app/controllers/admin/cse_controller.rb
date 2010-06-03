# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'gdata'
require 'lib/gdata-cse'

class Admin::CseController < ApplicationController
  before_filter :admin_required
  before_filter :check_purgatory
  before_filter :turn_off_right_column

  layout 'pubsite'

  def index
    set_titletag('Manage CSE Links - Pubsite Admin')
  end

  def new
  end

  def create
  end

  def destroy
  end

end
