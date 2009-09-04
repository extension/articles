# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  #protect_from_forgery # See ActionController::RequestForgeryProtection for details
  
  include LoginSystem
  include ExceptionNotifiable
  include InstitutionalLogo
  include ControllerExtensions

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  require 'zip_code_to_state'
  require 'image_size'
  
  before_filter :set_locale
  before_filter :unescape_params
  before_filter :personalize
  before_filter :set_request_url_options
  before_filter :set_default_request_ip_address
    
  def set_request_url_options
    if(!request.nil?)
      AppConfig.configtable['url_options']['host'] = request.host unless (request.host.nil?)
      AppConfig.configtable['url_options']['protocol'] = request.protocol unless (request.protocol.nil?)
      AppConfig.configtable['url_options']['port'] = request.port unless (request.port.nil?)
    end
  end
  
  def get_location_options
    locations = Location.find(:all, :order => 'entrytype, name')
    return [['', '']].concat(locations.map{|l| [l.name, l.id]})
  end
  
  def get_county_options
    if params[:location_id] and params[:location_id].strip != '' and location = Location.find(params[:location_id])
      counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return [['', '']].concat(counties.map{|c| [c.name, c.id]})
    end
  end
  
  def set_default_request_ip_address
    if(!request.env["HTTP_X_FORWARDED_FOR"].nil?)
      AppConfig.configtable['request_ip_address'] = request.env["HTTP_X_FORWARDED_FOR"]
    elsif(!request.env["REMOTE_ADDR"].nil?)
      AppConfig.configtable['request_ip_address'] = request.env["REMOTE_ADDR"]
    else
      AppConfig.configtable['request_ip_address'] = AppConfig.configtable['default_request_ip']
    end
  end
  
  def set_locale
    # update session if passed
    session[:locale] = params[:locale] if params[:locale]

    # set locale based on session or default 
    I18n.locale = session[:locale] || I18n.default_locale
  end
    
  # Account for the double encoding occuring at the webserver level by
  # decoding known trouble params again.
  def unescape_params
    [:content_tag, :order].each do |param|
      params[param] = CGI.unescape(params[param]) if params[param]      
    end
    if params[:categories] and params[:categories].class == Array
      params[:categories].collect! { |c| CGI.unescape(c) }
    end
  end
    
  def do_404
    personalize if not @personal
    @page_title_text = 'Status 404 - Page Not Found'
    render :template => "/shared/404", :status => "404"
  end
    
  private
  
  def turn_off_right_column
    @right_column = false    
  end
  
  # def disable_link_prefetching
  #   if request.env["HTTP_X_MOZ"] == "prefetch" 
  #     logger.debug "prefetch detected: sending 403 Forbidden" 
  #     render(:nothing => true, :status => 403)
  #     return false
  #   end
  # end
  
  def list_view_error(err_msg)
    redirect_to incoming_url
    flash[:failure] = err_msg
  end
  
  def personalize
    @personal = {}
    
    if session[:institution_id]
      begin
        inst = Institution.find(session[:institution_id])
      rescue
        session[:institution_id] = nil
      end
      @personal[:institution] = inst if inst
      if (inst and @personal[:location].nil?)
        @personal[:location] = @personal[:institution].location
      end
    elsif(refering_institution = Institution.find_by_referer(request.referer))
      session[:institution_id] = {:value => refering_institution.id.to_s, :expires => 1.month.from_now}
      @personal[:institution] = refering_institution
      @personal[:location] = refering_institution.location
    end
        
  end
  
  def set_title(main, sub = nil)
    @page_title_text = ERB::Util::html_escape(main)
    @header_description = sub
  end
  
  def set_titletag(main)
    @title_tag = ERB::Util::html_escape(main)
  end
  
  def admin_mode?
    if(!@currentuser.nil? && @currentuser.is_admin? && session[:adminmode] == @currentuser.id.to_s)
      return true
    else
      return false
    end
  end
  
  def set_content_tag
    @content_tag = nil
    
    if(!params[:content_tag].nil?)
      content_tag_name = params[:content_tag]
    elsif(!session[:content_tag].nil?)
      content_tag_name = session[:content_tag]
    else
      return @content_tag
    end
    
    if(!Tag::BLACKLIST.include?(content_tag_name))
      if(@content_tag = Tag.content_tags.find_by_name(Tag.normalizename(content_tag_name)))
        session[:content_tag] = @content_tag.name
      end
    end
    
    return @content_tag
  end
  
  def set_community(content_tag)
    @community = nil
    if(!content_tag.nil?)
      @community = content_tag.content_community 
    end
    return @community
  end
  
  def set_topic(community)
    @topic = nil
    if(!community.nil?)
      @topic = community.topic
    end
    
    return @topic
  end
  
  # sets @content_tag, @community and @topic for callers
  def set_content_tag_and_community_and_topic
    set_topic(set_community(set_content_tag))
    return true
  end
  
  #sets the instance variables based on parameters from views like incoming questions and resolved questions
   #if there was no category parameter, then use the category specified in the user's preferences if it exists
   def list_view(is_resolved = false)
     (is_resolved) ? field_to_sort_on = 'resolved_at' : field_to_sort_on = 'created_at'
            
     if params[:order] and params[:order] == "asc"
         @order = "submitted_questions.#{field_to_sort_on} asc"
         @toggle_order = "desc"
     # either no order parameter or order parameter is "desc"
     elsif !params[:order] or params[:order] == "desc"
       @order = "submitted_questions.#{field_to_sort_on} desc"
       @toggle_order = "asc"
     end
     
     # if there are no filter parameters, then find saved filter options if they exist
     if !params[:category] and !params[:location] and !params[:county] and !params[:source]
  
       # filter by category if it exists
       if (pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_FILTER_CATEGORY))
         if pref.setting == Category::UNASSIGNED
           @category = Category::UNASSIGNED
          else   
            @category = Category.find(pref.setting)
            if !@category
              flash[:failure] = "Invalid category."
              redirect_to incoming_url
              return
            end
          end
        end  

        # filter by location if it exists
        if (pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_FILTER_LOCATION))
          @location = Location.find_by_fipsid(pref.setting)
          if !@location
            flash[:failure] = "Invalid location."
            redirect_to incoming_url
            return
          end
        end

        # filter by county if it exists
        if (@location) and (pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_FILTER_COUNTY))
          @county = County.find_by_fipsid(pref.setting)
          if !@county
            flash[:failure] = "Invalid county."
            redirect_to incoming_url
            return
          end
        end
        
        # filter by source if it exists
        if pref = @currentuser.user_preferences.find_by_name(UserPreference::AAE_FILTER_SOURCE)
          @source = pref.setting
        end
        
        
     # parameters exist, process parameters and save preferences    
     else
       #process location preference
       if params[:location] == Location::ALL
         @location = nil
       elsif params[:location] and params[:location].strip != ''
         @location = Location.find(:first, :conditions => ["fipsid = ?", params[:location].strip])
         if !@location
           flash[:failure] = "Invalid location."
           redirect_to incoming_url
           return
         end
       end

       #process county preference
       if params[:county] == County::ALL
         @county = nil
       elsif params[:county] and params[:county].strip != ''
         @county = County.find(:first, :conditions => ["fipsid = ?", params[:county].strip])
         if !@county
           flash[:failure] = "Invalid county."
           redirect_to incoming_url
           return
         end
       end
      
       #process category preference
       if params[:category] == Category::UNASSIGNED
         @category = Category::UNASSIGNED
       elsif params[:category] == Category::ALL
         @category = nil
       elsif params[:category] and params[:category].strip != ''
         @category = Category.find(:first, :conditions => ["id = ?", params[:category].strip])
         if !@category
           flash[:failure] = "Invalid category."
           redirect_to incoming_url
           return  
         end
       end
       
       #process source preference
       if params[:source] == UserPreference::ALL
         @source = nil
       elsif params[:source] and params[:source].strip != '' and params[:source].strip != 'add_sources'
         @source = params[:source]
       end
         
       # save the category, location and source prefs from the filter

       #save category prefs
       user_prefs = @currentuser.user_preferences.find(:all, :conditions => "name = '#{UserPreference::AAE_FILTER_CATEGORY}'")
       if user_prefs
          user_prefs.each {|up| up.destroy}
       end
       
       if @category.class == Category
          cat_setting = @category.id
       elsif @category == Category::UNASSIGNED
         cat_setting = @category
       end

       if cat_setting
         up = UserPreference.new(:user_id => @currentuser.id, :name => UserPreference::AAE_FILTER_CATEGORY, :setting => cat_setting)
         up.save
       end

       #save location prefs
       user_prefs = @currentuser.user_preferences.find(:all, :conditions => "name = '#{UserPreference::AAE_FILTER_LOCATION}'")
       if user_prefs
         user_prefs.each {|up| up.destroy}
       end

       if @location 
         up = UserPreference.new(:user_id => @currentuser.id, :name => UserPreference::AAE_FILTER_LOCATION, :setting => @location.fipsid)
         up.save
       end

       #save county prefs
       user_prefs = @currentuser.user_preferences.find(:all, :conditions => "name = '#{UserPreference::AAE_FILTER_COUNTY}'")
       if user_prefs
         user_prefs.each {|up| up.destroy}
       end

       if @county 
         up = UserPreference.new(:user_id => @currentuser.id, :name => UserPreference::AAE_FILTER_COUNTY, :setting => @county.fipsid)
         up.save
       end
       
       #save source prefs
       user_prefs = @currentuser.user_preferences.find(:all, :conditions => "name = '#{UserPreference::AAE_FILTER_SOURCE}'")
       if user_prefs
         user_prefs.each{ |up| up.destroy}
       end
       
       if @source
         up = UserPreference.new(:user_id => @currentuser.id, :name => UserPreference::AAE_FILTER_SOURCE, :setting => @source)
         up.save
       end
       
       # end the save prefs section
     end
   end
   
   def filter_string_helper
     if !@category and !@location and !@county and !@source
       @filter_string = 'All'
     else
         filter_params = Array.new
         if @category
             if @category == Category::UNASSIGNED
                 filter_params << "Uncategorized"
             else
                 filter_params << @category.full_name
             end
         end
         if @location
             filter_params << @location.name
         end
         if @county
             filter_params << @county.name
         end

         if @source
           case @source
             when 'pubsite'
               filter_params << 'www.extension.org'
             when 'widget'
               filter_params << 'Ask eXtension widgets'
             else
               source_int = @source.to_i
               if source_int != 0
                 widget = Widget.find(:first, :conditions => "id = #{source_int}")
               end

               if widget
                 filter_params << "#{widget.name} widget"
               end
           end  
         end

         @filter_string = filter_params.join(' + ')
     end
   end
  
  def params_errors
    if params[:page] and params[:page].to_i == 0 
      return "Invalid page number"
    else
      return nil
    end
  end
  
  def set_filters
    source_filter_prefs = @currentuser.user_preferences.find(:all, :conditions => "name = '#{UserPreference::FILTER_WIDGET_ID}'").collect{|pref| pref.setting}.join(',')
    widgets_to_filter = Widget.find(:all, :conditions => "widgets.id IN (#{source_filter_prefs})", :order => "name") if source_filter_prefs and source_filter_prefs.strip != ''
    @source_options = [['All Sources', 'all'], ['www.extension.org', 'pubsite'], ['All Ask eXtension widgets', 'widget']]
    @source_options = @source_options.concat(widgets_to_filter.map{|w| [w.name, w.id.to_s]}) if widgets_to_filter
    @source_options = @source_options.concat([['', ''], ['Edit source list','add_sources']])
    @widget_filter_url = url_for(:controller => 'aae/prefs', :action => 'widget_preferences', :only_path => false)
  end
  
  def go_back
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to incoming_url)
  end
  
end

# custom error classes
class ContentRetrievalError < StandardError
end
