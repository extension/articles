# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Admin::LogosController < ApplicationController
  before_filter :admin_required
  before_filter :check_purgatory
  before_filter :turn_off_right_column

  def index
    set_titletag('Manage Logos- Pubsite Admin')
    @logos = Logo.find(:all, :conditions => { :parent_id => nil }, :order => 'created_at DESC')
  end

  def new
    @logo = Logo.new
  end

  def create
    @logo = Logo.new(params[:logo])

    if @logo.save
      flash[:notice] = 'Logo was successfully uploaded.'
      redirect_to(admin_logos_url)
    else
      render(:action => "new")
    end
  end

  def destroy
    @logo = Logo.find(params[:id])
    @logo.destroy
    redirect_to(admin_logos_url)
  end    
    
end
