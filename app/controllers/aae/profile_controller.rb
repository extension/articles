# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::ProfileController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory  
    
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
     
     @questions=@user.open_questions

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
        @auto_route_msg += "<a href='/aae/prefs/index'>edit</a>"
      end
      @auto_route_msg = "<p>".concat(@auto_route_msg).concat("</p>")   
    end
  end
  
  # when an expert search is complete and the assignee clicks on an expert's link in the returned search 
  # results, this function is called to populate the information about the expert under the expert's name
  def show_profile
    user = User.find(params[:id])
    
    # populate_profile is used the first time the expert's name is clicked on. 
    # it pulls the profile info. from the db. all other subsequent clicks on the 
    # expert's name just shows the profile but does not need to hit the db.
    render :update do |page|
      if params[:populate_profile]
        user_expertise = user.categories.find(:all, :order => 'name')
        user_expertise_locations = user.expertise_locations
        
        # populate profile information for expert under expert's name
        page.replace_html "expert_profile_#{user.id}", :partial => 'user_bio', :locals => { :user_bio => user, :user_expertise => user_expertise, :user_expertise_locations => user_expertise_locations }
        # replace the link for the expert in the returned list with appropriate params so we know not 
        # to hit the db the next time it's clicked on.
        page.replace_html "expert_link_#{user.id}", :partial => 'expert_profile_link', :locals => { :user => user }
        page.visual_effect :toggle_blind, "expert_profile_#{user.id}"
      else
        page.visual_effect :toggle_blind, "expert_profile_#{user.id}"
      end
    end
  end
  
end