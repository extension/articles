class CountyLinksController < ApplicationController

  before_filter :check_authentication
  before_filter :check_authorization
  before_filter :set_page_title

  def index
    @county_links = CountyLink.find(:all)
  end

  def show
    if params[:id].nil?
      redirect_to :action => 'index'
    else
      redirect_to :action => 'edit', :id => params[:id]
    end
  end

  def new
    @county_link = CountyLink.new
  end

  def edit
    @county_link = CountyLink.find(params[:id])
  end

  def create
    @county_link = CountyLink.new(params[:county_link])

    if @county_link.save
      flash[:notice] = 'Link uploaded.'
      redirect_to county_links_url
    else
      flash[:error] = "Error saving link."
      render :action => 'new'
    end
  end

  def update
    @county_link = CountyLink.find(params[:id])
  
    if @county_link.update_attributes(params[:county_link])
      flash[:notice] = 'Link was successfully updated.'
      redirect_to county_link_url(@county_link)
    else
      flash[:error] = "Error updating link."
      render :action => "edit"
    end
  end

  def destroy
    @county_link = CountyLink.find(params[:id])
    @county_link.destroy
    redirect_to county_links_url
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
    set_title('Manage County Links')
  end
end