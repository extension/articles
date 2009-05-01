class FeedLocationsController < ApplicationController

  before_filter :check_authentication
  before_filter :check_authorization
  
  def index
    @feed_locations = FeedLocation.all
  end

  def edit
    @feed_location = FeedLocation.find(params[:id])
  end

  def update
    @feed_location = FeedLocation.find(params[:id])  
    if @feed_location.update_attributes(params[:feed_location])
      flash[:notice] = 'Feed source was successfully updated.'
      redirect_to feed_locations_path
    else
      flash[:error] = "Error updating feed source."
      render :action => "edit"
    end
  end
  
  def new
    @feed_location = FeedLocation.new
  end

  def create
    @feed_location = FeedLocation.new(params[:feed_location])
    if @feed_location.save
      flash[:notice] = 'Feed source created.'
      redirect_to feed_locations_url
    else
      flash[:error] = "Error created feed source."
      render :action => 'new'
    end
  end
  
  def destroy
    @feed_location = FeedLocation.find(params[:id])
    @feed_location.destroy
    flash[:notice] = "Successfully deleted the feed source"
    redirect_to feed_locations_path
  end
  
  
  # TODO: can all this auth filtering be defined in app controller instead?
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
end