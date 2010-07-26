# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class Aae::ExpertiseController < ApplicationController
  layout 'aae'
  before_filter :login_required
  before_filter :check_purgatory  
  
  # they can specify their areas of expertise by category/subcategory 
  def categories
    @categories = Category.root_categories.all(:order => 'name')
    @current_user_categories = @currentuser.get_expertise
    
    if request.post?      
      if params[:legacycategory]
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
  
  def experts_by_category
    filteredparams = ParamsFilter.new([:legacycategory],params)
    if(@category = filteredparams.legacycategory)
      if @category == Category::UNASSIGNED
        @category_name = "AaE Uncategorized Question Wrangler"
        @users = User.question_wranglers 
      else  
        @category_name = @category.name
        @users = @category.users
      end
    else
      flash[:failure] = "Invalid Category"
      request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to incoming_url)
      return
    end
  end
  
  def experts_by_location
    if params[:id]
      @location = ExpertiseLocation.find(:first, :conditions => ["fipsid = ?", params[:id].to_i])
      if !@location
        flash[:failure] = "Invalid Location Entered"
        redirect_to incoming_url
      else
        @users = @location.users.find(:all, :order => "users.first_name")
      end
    else
      flash[:failure] = "Invalid Location Entered"
      redirect_to incoming_url
    end
  end
  
  def change_category_public_visibility
    @category = Category.find_by_id(params[:id])
    
    if(params[:show_to_public] && params[:show_to_public] == 'yes' )
       @category.update_attribute(:show_to_public, true)
       AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_PUBLIC_CATEGORY,{:category_id => @category.id, :show_to_public => false})       
     else
       @category.update_attribute(:show_to_public, false)
       AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_PUBLIC_CATEGORY,{:category_id => @category.id, :show_to_public => false})       
    end
        
    respond_to do |format|
      format.js
    end
  end
  
  def change_subcategory_public_visibility
    @subcategory = Category.find_by_id(params[:id])
    
    if(params[:show_to_public] && params[:show_to_public] == 'yes' )
       @subcategory.update_attribute(:show_to_public, true)
       AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_PUBLIC_CATEGORY,{:category_id => @subcategory.id, :show_to_public => false})       
     else
       @subcategory.update_attribute(:show_to_public, false)
       AdminEvent.log_event(@currentuser, AdminEvent::UPDATE_PUBLIC_CATEGORY,{:category_id => @subcategory.id, :show_to_public => false})       
    end
        
    respond_to do |format|
      format.js
    end
  end
  
end