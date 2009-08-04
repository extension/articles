# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::ProfileController < ApplicationController
  
  layout 'aae'
  before_filter :login_required
  
  def index
    if params[:id].nil? || params[:id].length == 0
      flash[:failure] = "No eXtension ID specified.";
      redirect_to incoming_url
      return
    end

    @myid = @currentuser.id
    @user = User.find(:first, :conditions => ["login = ?", params[:id]])

    if @user.nil?
      flash[:failure] = "eXtension ID does not exist.";
      redirect_to incoming_url
      return
    end

    location_only = @user.user_preferences.find_by_name(UserPreference::AAE_LOCATION_ONLY)
    county_only = @user.user_preferences.find_by_name(UserPreference::AAE_COUNTY_ONLY)

    @geo_info = "*Indicated in prefs to not assign questions outside of marked states/locations." if location_only
    @geo_info = "*Indicated in prefs to not assign questions outside of marked counties." if county_only
    @geo_info = "*Indicated in prefs that you may route questions outside of the specified geographic regions." if !defined?(@geo_info)

    if @user.is_answerer? 
      @auto_route_msg = ""   
    else
      @auto_route_msg = "*Has not indicated in prefs to receive auto-routed questions. "
      if @user.id == @currentuser.id 
        @auto_route_msg += "<a href='/ask/prefs/index'>edit</a>"
      end
      @auto_route_msg = "<p>".concat(@auto_route_msg).concat("</p>")   
    end
  end
  
  def profile_tooltip
    @user = User.find_by_login(params[:login])
    
    if @user
      render :template => 'aae/profile/profile_tooltip.js.rjs'
    else
      render :nothing => true
    end
  end
  
end