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
      AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_FEED_LOCATION,{:feed_location_id => @feed_location.id,:feed_location_uri => @feed_location.uri})
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
      AdminEvent.log_event(@currentuser, AdminEvent::CREATE_FEED_LOCATION,{:feed_location_id => @feed_location.id,:feed_location_uri => @feed_location.uri})
      flash[:notice] = 'Feed source created.'
      redirect_to admin_feed_locations_url
    else
      flash[:error] = "Error created feed source."
      render :action => 'new'
    end
  end
  
  def destroy
    @feed_location = FeedLocation.find(params[:id])
    AdminEvent.log_event(@currentuser, AdminEvent::DELETE_FEED_LOCATION,{:feed_location_id => @feed_location.id, :feed_location_uri => @feed_location.uri})
    @feed_location.destroy
    flash[:notice] = "Successfully deleted the feed source"
    redirect_to admin_feed_locations_url
  end
  
end