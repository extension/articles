# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Admin::LogosController < ApplicationController
  before_filter :admin_signin_required
  before_filter :turn_off_resource_areas

  layout 'frontporch'

  def index
    set_title('Manage Logos - Pubsite Admin')
    @logos = Logo.sponsorlogos.find(:all, :conditions => { :parent_id => nil }, :order => 'created_at DESC')
  end

  def new
    @logo = Logo.new
  end

  def create
    @logo = Logo.new(params[:logo])
    @logo.logotype = Logo::SPONSOR

    if @logo.save
      flash[:notice] = 'Logo was successfully uploaded.'
      AdminLog.log_event(current_person, AdminLog::CREATE_LOGO,{:logo_id => @logo.id, :logo_filename => @logo.filename})
      redirect_to(admin_logos_url)
    else
      render(:action => "new")
    end
  end

  def destroy
    @logo = Logo.find(params[:id])
    AdminLog.log_event(current_person, AdminLog::DELETE_LOGO,{:logo_id => @logo.id, :logo_filename => @logo.filename})
    @logo.destroy
    redirect_to(admin_logos_url)
  end

end
