class CountyLinksController < ApplicationController

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
  
  def set_page_title
    set_title('Manage County Links')
  end
end