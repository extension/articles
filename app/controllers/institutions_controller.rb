class InstitutionsController < ApplicationController

  before_filter :check_authentication
  before_filter :check_authorization
  before_filter :set_page_title

  def index
    @institutions = Institution.find(:all, :order => 'state')
    @right_column = false
  end

  def show
    if params[:id].nil?
      redirect_to :action => 'index'
    else
      redirect_to :action => 'edit', :id => params[:id]
    end
  end

  def new
  end

  def edit
    @institution = Institution.find(params[:id])
    @right_column = false
  end

  def update
    @institution = Institution.find(params[:id])
  
    if @institution.update_attributes(params[:institution])
      flash[:notice] = 'Institution was successfully updated.'
      redirect_to :action => 'index', :id => @institution
    else
      flash[:error] = "Error updating link."
      render :action => "edit"
    end
  end 

protected

  def check_authorization 
    if current_user == :false || ! has_right?(current_user)
      bounce_unauthorized_user
      return false 
    end 
  end

  def bounce_unauthorized_user
    flash[:notice] = "You are not authorized to view the page you requested." 
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to home_url)
  end

  def has_right?(user)
    user.has_right_for?(action_name, self.class.controller_path)
  end
  
  def set_page_title
    set_title('Manage Institutions')
  end
end