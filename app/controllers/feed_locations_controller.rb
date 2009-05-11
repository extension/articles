class FeedLocationsController < ApplicationController

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
  
end