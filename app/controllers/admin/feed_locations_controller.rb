# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Admin::FeedLocationsController < ApplicationController
  before_filter :admin_required
  before_filter :check_purgatory
  before_filter :turn_off_right_column


  def index
    @feed_locations = FeedLocation.all
    set_titletag("External Feeds Management - Pubsite Admin")
  end

  def edit
    @feed_location = FeedLocation.find(params[:id])
    set_titletag("Edit Feed Source - Pubsite Admin")
  end

  def update
    @feed_location = FeedLocation.find(params[:id])  
    if @feed_location.update_attributes(params[:feed_location])
      # TODO: log action
      flash[:notice] = 'Feed source was successfully updated.'
      redirect_to admin_feed_locations_url
    else
      flash[:error] = "Error updating feed source."
      render :action => "edit"
    end
  end
  
  def new
    @feed_location = FeedLocation.new
    set_titletag("New Feed Source - Pubsite Admin")
  end

  def create
    @feed_location = FeedLocation.new(params[:feed_location])
    if @feed_location.save
      # TODO: log action
      flash[:notice] = 'Feed source created.'
      redirect_to admin_feed_locations_url
    else
      flash[:error] = "Error created feed source."
      render :action => 'new'
    end
  end
  
  def destroy
    # TODO: log action
    @feed_location = FeedLocation.find(params[:id])
    @feed_location.destroy
    flash[:notice] = "Successfully deleted the feed source"
    redirect_to admin_feed_locations_url
  end
  
end