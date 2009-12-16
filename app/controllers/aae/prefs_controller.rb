# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE


class Aae::PrefsController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory  
  skip_before_filter :unescape_params

  # they can specify their areas of expertise by category/subcategory 
  def expertise
    @categories = Category.root_categories
    @current_user_categories = @currentuser.get_expertise
    
    if request.post?      
      if params[:category]
        selected_category = Category.find_by_id(params[:category].strip)
        if selected_category
          if @currentuser.categories.include?(selected_category)
            @currentuser.categories.delete(selected_category)
            expertise_event = ExpertiseEvent.new(:category => selected_category, :event_type => ExpertiseEvent::EVENT_DELETED, :user => @currentuser)
            @currentuser.expertise_events << expertise_event
            @currentuser.delete_all_subcat_expertise(selected_category)
            if selected_category.is_top_level?
              deleted_top_level = true
            end
          else
            @currentuser.categories << selected_category
            
            # add people tags
            @currentuser.tag_with(selected_category.name, @currentuser.id,Tag::USER)
            
            expertise_event = ExpertiseEvent.new(:category => selected_category, :event_type => ExpertiseEvent::EVENT_ADDED, :user => @currentuser)
            @currentuser.expertise_events << expertise_event
          end
          @currentuser.save
        end
      end
      
      render :update do |page|
        page.visual_effect :highlight, selected_category.id
        #page.replace "subcats_of_#{selected_category.parent.id}", :partial => 'subcategories', :locals => {:top_level_category => selected_category} if !selected_category.is_top_level?
        page.replace_html "subcategory_div#{selected_category.parent.id}", :partial => 'subcategories', :locals => {:top_level_category => selected_category.parent} if !selected_category.is_top_level?     
        if selected_category.is_top_level?
          if deleted_top_level
            page.replace_html "subcategory_div#{selected_category.id}", '' 
          else
            page.replace_html "subcategory_div#{selected_category.id}", :partial => 'subcategories', :locals => {:top_level_category => selected_category}         
          end
        end
      end
      return
    end
    
  end
  
  #kicks off at the start of the location selection page for the user
  def location
    @locations = ExpertiseLocation.find(:all, :order => 'entrytype, name')
  end
  
  #this will fire when a single county is removed or all counties for a user's location are removed
  #if there is a location_option parameter passed in, then all of the user's counties for that location need to be removed
  #if there is a county_option passed in, then just the one county needs to be removed from the user's counties, but if 
  #it is the last county for that location being removed, then the location for the user gets removed as well
  def delete_counties
    if params[:location_option] and params[:location_option].strip != ''
      @location = ExpertiseLocation.find_by_fipsid(params[:location_option])
      @currentuser.expertise_locations.delete(@location)
      counties_to_delete = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.state_fipsid = #{@location.fipsid}")
      @currentuser.expertise_counties.delete(counties_to_delete)
      @delete_location = true
    elsif params[:county_option] and params[:county_option].strip != ''
      county = ExpertiseCounty.find_by_fipsid(params[:county_option])
      @location = county.expertise_location
      @currentuser.expertise_counties.delete(county)
      @county_list = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.state_fipsid = #{@location.fipsid}")
      if @county_list.length == 0
        @currentuser.expertise_locations.delete(@location) 
        @delete_location = true
      end
    end
    
    respond_to do |format|
       format.js
    end
  end
  
  #this will fire when a single county is added or all counties for a particular location are added to the user's preferences
  #for all counties, instead of appending all of them to the user's preferences, there is a special county with a countycode equal to 
  #'0' for each location that lets the app know that all counties are specified for that location
  #if params[:all] is used, then add all counties for that particular location
  #if params[:new_county_fips] is used, then add just the one county selected
  #one will replace the other, so if all is selected and the user picks an individual county, then all will be replaced with the single county and vice versa
  def add_counties
    if params[:location_fips]
      location_fips = params[:location_fips]
      @location = ExpertiseLocation.find_by_fipsid(location_fips)
      
      if params[:all] and params[:all].strip != ''
        #replace existing counties for this location with the 'all county' county
        existing_counties = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.state_fipsid = #{@location.fipsid}")
        if existing_counties.length > 0
          @currentuser.expertise_counties.delete(existing_counties)
        end
        @all_counties = true  
        county_to_add = @location.expertise_counties.find(:first, :conditions => "countycode = '0'")
      elsif params[:new_county_fips] and params[:new_county_fips].strip != ''
        all_county = @currentuser.expertise_counties.find(:first, :conditions => "expertise_counties.state_fipsid = #{@location.fipsid} and expertise_counties.countycode = '0'")
        @currentuser.expertise_counties.delete(all_county) if all_county
        @new_county = true
        county_to_add = ExpertiseCounty.find(:first, :conditions => ["expertise_counties.fipsid = ?", params[:new_county_fips]] )
      end
      
      @currentuser.expertise_locations << @location if !@currentuser.expertise_locations.find(:first, :conditions => "expertise_locations.id = #{@location.id}")
      @currentuser.expertise_counties << county_to_add if !@currentuser.expertise_counties.find(:first, :conditions => "expertise_counties.id = #{county_to_add.id}")
      @currentuser.save
      
      @new_county_list = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.state_fipsid = #{@location.fipsid}")
    end
    
    respond_to do |format|
      format.js
    end
  end

   #action for a request made via an AJAX action from the location selection page that takes the parameters for state and county to construct
   #a mysql query that will return all counties that start with the letters given for the county parameter
   #and have the same fipsid as the location parameter.
   def list_counties
     if (params[:county] and params[:county].strip != "") and (params[:location_option] and params[:location_option].strip != "")
       @counties = County.find(:all, :conditions => ["name like ? and state_fipsid = ? and countycode <> '0'", params[:county] + '%', params[:location_option]])  
     else
       @counties = []
     end

     render :layout => false
   end
     
   #this action will execute when...
   #1. the user clicks on the add or edit a location link OR
   #2. the user clicks on the edit link beside the location on the location summary OR
   #3. the user selects a location from the drop-down list
   #the params[:edit_location_fipsid] is passed in from the edit link on the location summary
   #the params[:location_fips] is passed in from the location drop down
   def show_counties
     if params[:location_fips] and params[:location_fips].strip != ''
       @location = ExpertiseLocation.find_by_fipsid(params[:location_fips])
       @selected_counties = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.expertise_location_id = #{@location.id}", :order => "expertise_counties.name")
     else
       locations = ExpertiseLocation.find(:all, :order => 'entrytype, name')
       if params[:edit_location_fipsid]
         @location = ExpertiseLocation.find_by_fipsid(params[:edit_location_fipsid])
         @location_selected = @location.fipsid
         @selected_counties = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.expertise_location_id = #{@location.id}", :order => "expertise_counties.name")
       #if the user clicks on the add or edit a location link
       else
         @location_selected = [""]
       end
       @location_options = [""].concat(locations.map{|l| [l.name,l.fipsid]})
     end
     respond_to do |format|
       format.js
     end
   end
   
   #action that gets called via an AJAX action called from the location selection page's page load event.
   #this does the querying to retrieve all of the existing location and county data for the current user.
   #the initialize_locations.rjs template gets rendered when this call executes.
   def initialize_locations
     @location_array = Array.new
     
     locations = @currentuser.expertise_locations.find(:all, :order => 'name')
     
     locations.each do |l|
       selected_counties = @currentuser.expertise_counties.find(:all, :conditions => "expertise_counties.expertise_location_id = #{l.id}", :order => "expertise_counties.name")
       if selected_counties.length > 0
         @location_array << [l, selected_counties]
       end
     end
     
     respond_to do |format|
        format.js
     end
   end
  
  def get_subcategories
    @category = Category.find_by_id(params[:category])

    if !@category 
      logger.info "Removing subcategory"
      render :text => "", :layout => false
      return
    elsif @category.children.length == 0
      render :text => "", :layout => false
      return
    end
    
    render :layout => false
  end
   
  def widget_preferences
    if !request.post?
      @widgets = Widget.find(:all, :order => "name")
      @filter_widgets = UserPreference.find(:all, :conditions => "user_id = #{@currentuser.id} and name = '#{UserPreference::FILTER_WIDGET_ID}'").collect{|pref| pref.setting.to_i}
      role_for_widget_routing = Role.find(:first, :conditions => "name = '#{Role::WIDGET_AUTO_ROUTE}'")
      @auto_assign_widgets = UserRole.find(:all, :conditions => "user_id = #{@currentuser.id} and role_id = #{role_for_widget_routing.id}").collect{|role| role.widget_id}
    else
      if params[:filter_widget_id] and params[:filter_widget_id].strip != ''
        widget = Widget.find(:first, :conditions => ["id = ?", params[:filter_widget_id].strip])
        if user_pref = UserPreference.find(:first, :conditions => ["user_id = #{@currentuser.id} and name = '#{UserPreference::FILTER_WIDGET_ID}' and setting = ?", widget.id])
          user_pref.destroy
          # if the user has removed the widget from their filter options and still has the source filter set to filter aae questions by that widget, then remove that filter pref also
          if aae_list_source_filter = UserPreference.find(:first, :conditions => ["user_id = #{@currentuser.id} and name = '#{UserPreference::AAE_FILTER_SOURCE}' and setting = ?", widget.id])
            aae_list_source_filter.destroy
          end
        else
          user_pref = UserPreference.new(:user => @currentuser, :name => UserPreference::FILTER_WIDGET_ID, :setting => widget.id)
          user_pref.save
        end
      elsif params[:widget_auto_assign_id] and params[:widget_auto_assign_id].strip != ''
        widget = Widget.find(:first, :conditions => ["id = ?", params[:widget_auto_assign_id].strip])
        role_for_widget_routing = Role.find(:first, :conditions => "name = '#{Role::WIDGET_AUTO_ROUTE}'")
        
        widget_route_role = UserRole.find(:first, :conditions => ["user_id = #{@currentuser.id} and widget_id = ? and role_id = #{role_for_widget_routing.id}", widget.id])
        if widget_route_role
          widget_route_role.destroy
        else
          role_to_save = UserRole.new(:user => @currentuser, :role => role_for_widget_routing, :widget => widget)
          role_to_save.save
        end
      end
      
      render :update do |page|
        page.visual_effect :highlight, widget.name
      end
      
    end
    
  end
  
  def get_widgets    
    @filter_widgets = UserPreference.find(:all, :conditions => "user_id = #{@currentuser.id} and name = '#{UserPreference::FILTER_WIDGET_ID}'").collect{|pref| pref.setting.to_i}
    role_for_widget_routing = Role.find(:first, :conditions => "name = '#{Role::WIDGET_AUTO_ROUTE}'")
    @auto_assign_widgets = UserRole.find(:all, :conditions => "user_id = #{@currentuser.id} and role_id = #{role_for_widget_routing.id}").collect{|role| role.widget_id}
    widget_name = params[:widget_name]
    @widgets = Widget.find(:all, :conditions => "name like '#{widget_name}%'", :order => "name")
    
    render :partial => "widget_list", :layout => false
  end
  
  def index
    auto_route_role = Role.find_by_name(Role::AUTO_ROUTE)
    escalation_role = Role.find_by_name(Role::ESCALATION)
    
    signature_pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_SIGNATURE)
    signature_pref ? @signature = signature_pref.setting : @signature = "-#{@currentuser.fullname}"
    @location_only = @currentuser.user_preferences.find_by_name(UserPreference::AAE_LOCATION_ONLY)
    @county_only = @currentuser.user_preferences.find_by_name(UserPreference::AAE_COUNTY_ONLY)
    @no_assign = !@currentuser.aae_responder
  
    (auto_route_role.users.include?(@currentuser)) ? @auto_route = true : @auto_route = false
    (escalation_role.users.include?(@currentuser)) ? @auto_escalate = true : @auto_escalate = false  
    
    render :layout => 'aae'   
  end
  
  # when the 'do not assign me anything' box is checked, not only is the flag set to 
  # disable any assignment to this person, but also their auto-route preference is removed
  def toggle_no_assign
    if request.post?
      # if they checked the box
      if params[:check_box_value] == "1"
        if @currentuser.aae_responder
          @currentuser.update_attribute(:aae_responder, false)
          # take away their auto-route preference
          if role_to_delete = @currentuser.aae_auto_route_role
            role_to_delete.destroy
          end
        end
      # if they unchecked the box
      else
        if !@currentuser.aae_responder
          @currentuser.update_attribute(:aae_responder, true)
        end
      end
      render :update do |page|
        page.visual_effect :highlight, "no_assign_fieldset"
        # uncheck auto route box and disable the fields for it if they checked to not get routed anything
        if !@currentuser.aae_responder
          page.replace_html :auto_assign_warning, "<p class='warning'>These options are disabled because \"Don't assign me questions\" is selected.</p>" 
          page['auto_assign_options'].className = 'disabled'
          page.select('#auto_assign_options input').all('allInputs') do |value, index|
            value.disable
          end
        # re-enable the auto assign fields if they have unchecked the box to not get routed anything
        else
          page.replace_html :auto_assign_warning, ""
          page['auto_assign_options'].className = ''
          page.select('#auto_assign_options input').all('allInputs') do |value, index|
            value.enable
          end
        end
      end
    else
      do_404
      return
    end
  end
  
  def toggle_auto_assign
    if request.post?
      # if they checked the box
      if params[:check_box_value] == "1"
        if !@currentuser.aae_auto_route_role     
          @currentuser.roles << Role.find_by_name(Role::AUTO_ROUTE)
        end
      # if they unchecked the box
      else
        if auto_route_role = @currentuser.aae_auto_route_role
          auto_route_role.destroy
        end
      end
    render :update do |page|
      page.visual_effect :highlight, "auto_assign_options"
    end
    
    else
      do_404
      return
    end
  end
  
  def toggle_route_only_to_county
    if request.post?
      # if they checked the box
      if params[:check_box_value] == "1"
        if !@currentuser.user_preferences.find_by_name(UserPreference::AAE_COUNTY_ONLY)
          @currentuser.user_preferences << UserPreference.new(:name => UserPreference::AAE_COUNTY_ONLY, :setting => 1)
        end
      # if they unchecked the box
      else
        if county_only_pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_COUNTY_ONLY)
          county_only_pref.destroy
        end
      end
    
    render :update do |page|
      page.visual_effect :highlight, "county_only_li"
    end
        
    else
      do_404
      return
    end  
  end
  
  def toggle_route_only_to_location
    if request.post?
      # if they checked the box
      if params[:check_box_value] == "1"
        if !@currentuser.user_preferences.find_by_name(UserPreference::AAE_LOCATION_ONLY)
          @currentuser.user_preferences << UserPreference.new(:name => UserPreference::AAE_LOCATION_ONLY, :setting => 1)
        end
      # if they unchecked the box
      else
        if location_only_pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_LOCATION_ONLY)
          location_only_pref.destroy
        end
      end
    
    render :update do |page|
      page.visual_effect :highlight, "location_only_li"
    end
        
    else
      do_404
      return
    end  
  end
  
  def toggle_escalation
    if request.post?
      # if they checked the box  
      if params[:check_box_value] == "1"
        if !@currentuser.aae_escalation_role
          @currentuser.roles << Role.find_by_name(Role::ESCALATION)
        end
      # if they unchecked the box  
      else
        if escalation_role = @currentuser.aae_escalation_role
          escalation_role.destroy  
        end  
      end
      
      render :update do |page|
        page.visual_effect :highlight, "escalation_fieldset"
      end
      
    else
      do_404
      return
    end
  end
  
  def set_signature
    if request.post?
      if params[:signature]
        if !signature_pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_SIGNATURE)
          @currentuser.user_preferences << UserPreference.new(:name => UserPreference::AAE_SIGNATURE, :setting => params[:signature].strip)
        else
          signature_pref.update_attribute(:setting, params[:signature].strip)
        end
        render :update do |page|
          page.visual_effect :highlight, "email_signature"
        end
      end
    else
      do_404
      return
    end
  end
  
  private
  
  def delete_user_roles(user, conditions)
    user_roles_to_delete = user.user_roles.find(:all, :conditions => conditions)        
    if user_roles_to_delete and user_roles_to_delete.length > 0
      user_roles_to_delete.each{|rd| rd.destroy}
    end    
  end
    
end
