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
  include AuthLib
  include ControllerExtensions
  include SslRequirement
  rescue_from WillPaginate::InvalidPage, :with => :do_invalid_page
  helper_method :current_person


  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  require 'zip_code_to_state'
  require 'image_size'

  before_filter :set_default_request_ip_address
  before_filter :set_analytics_visitor
  before_filter :set_locale
  before_filter :unescape_params
  before_filter :personalize_location_and_institution
  before_filter :set_request_url_options
  before_filter :set_app_location
  before_filter :set_currentuser_time_zone

  has_mobile_fu
  skip_before_filter :set_mobile_format
  before_filter :mobile_detection

  helper_method :get_location_options
  helper_method :get_county_options
  helper_method :with_content_tag?
  helper_method :admin_mode?
  helper_method :content_tag_url_display_name
  
  def set_app_location
    @app_location_for_display = AppConfig.configtable['app_location']
  end
  
  def mobile_detection
    if is_mobile_device?
      @mobile_device = true
    end
  end
    
  def set_request_url_options
    if(!request.nil?)
      AppConfig.configtable['url_options']['host'] = request.host unless (request.host.nil?)
      AppConfig.configtable['url_options']['protocol'] = request.protocol unless (request.protocol.nil?)
      AppConfig.configtable['url_options']['port'] = request.port unless (request.port.nil?)
    end
  end
  
  def content_date_sort(articles, faqs, limit)
		merged = Hash.new
		retarray = Array.new
		articles.each{ |article| merged[article.source_updated_at] = article }
		faqs.each{ |faq| merged[faq.source_updated_at] = faq }
		tstamps = merged.keys.sort.reverse # sort by updated, descending
		tstamps.each{ |key| retarray << merged[key] }
		return retarray.slice(0,limit)
	end
  
  def get_location_options
    locations = Location.find(:all, :order => 'entrytype, name')
    return [['', '']].concat(locations.map{|l| [l.name, l.id]})
  end
  
  def get_county_options(provided_location = nil)
    if params[:location_id] and params[:location_id].strip != '' and location = Location.find(params[:location_id])
      counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return ([['', '']].concat(counties.map{|c| [c.name, c.id]}))
    elsif(provided_location)
      counties = provided_location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
      return ([['', '']].concat(counties.map{|c| [c.name, c.id]}))
    end
  end
  
  def set_default_request_ip_address
    # if(!request.env["HTTP_X_FORWARDED_FOR"].nil?)
    #   AppConfig.configtable['request_ip_address'] = request.env["HTTP_X_FORWARDED_FOR"]
    # elsif(!request.env["REMOTE_ADDR"].nil?)
    if(!request.env["REMOTE_ADDR"].nil?)
      AppConfig.configtable['request_ip_address'] = request.env["REMOTE_ADDR"]
    else
      AppConfig.configtable['request_ip_address'] = AppConfig.configtable['default_request_ip']
    end
    return true
  end
  
  def set_analytics_visitor
    if(session[:account_id])
      if(account = Account.find_by_id(session[:account_id]))
        @analytics_vistor = (account.class == User) ? 'internal' : 'external'
      else
        @analytics_vistor = 'anonymous'
      end
    else
      @analytics_vistor = 'anonymous'
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
    
    personalize_location_and_institution if not @personal
    @page_title_text = 'Status 404 - Page Not Found'
    render(:template => "/shared/404", :layout => 'pubsite', :status  => "404")
  end
  
  def do_410
    personalize_location_and_institution if not @personal
    @page_title_text = 'Status 410 - Page Removed'
    render :template => "/shared/410", :status => "410"
  end
  
  def do_invalid_page
    render :text => 'Invalid page requested', :status => 400
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
  
  def personalize_location_and_institution
    @personal = {}
    
    # get location and county from session, then IP
    if(!session[:location_and_county].blank? and !session[:location_and_county][:location_id].blank?)
      @personal[:location] = Location.find_by_id(session[:location_and_county][:location_id])
      if(!session[:location_and_county][:county_id].blank?)
        @personal[:county] = County.find_by_id(session[:location_and_county][:county_id])
      end
    end
    
    if(@personal[:location].blank?)
      if(location = Location.find_by_geoip)
        @personal[:location] = location
        session[:location_and_county] = {:location_id => location.id}
        if(county = County.find_by_geoip)
          @personal[:county] = county
          session[:location_and_county][:county_id] = county.id
        end
      end
    end
    
        
    if(!session[:branding_institution_id].nil?)
      search_id = session[:branding_institution_id]
      begin
        personalized_institution = BrandingInstitution.find_by_id(search_id)        
      rescue
        session[:branding_institution_id] = nil
      end
      @personal[:institution] = personalized_institution if(!personalized_institution.nil?)
      if (personalized_institution and @personal[:location].nil?)
        @personal[:location] = @personal[:institution].location
      end
    elsif(refering_institution = BrandingInstitution.find_by_referer(request.referer))
      session[:branding_institution_id] = refering_institution.id.to_s
      @personal[:institution] = refering_institution
    elsif(@personal[:location])
      branding_institutions_for_location = @personal[:location].branding_institutions
      if(!branding_institutions_for_location.blank?)
        if(branding_institutions_for_location.size == 1)
          @personal[:institution] = branding_institutions_for_location[0]
          session[:branding_institution_id] = @personal[:institution].id.to_s
          session[:multistate] = nil
        else
          @branding_institutions_for_location = branding_institutions_for_location
          session[:multistate] =  @personal[:location].abbreviation
        end
      end
    end
    return true
  end
  
  def set_title(main, sub = nil)
    @page_title_text = ERB::Util::html_escape(main)
    @header_description = sub
  end
  
  def set_titletag(main)
    @title_tag = ERB::Util::html_escape(main)
  end
  
  def admin_mode?
    if(!@currentuser.nil? && @currentuser.is_admin?)
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
   
  def params_errors
    if params[:page] and params[:page].to_i == 0 
      return "Invalid page number"
    else
      return nil
    end
  end
  
  def get_humane_date(time)
    time.strftime("%B %e, %Y, %l:%M %p")
  end
  
  def content_tag_url_display_name(content_tag)
    Tag.url_display_name(content_tag.downcase)
  end
  
  def go_back
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to incoming_url)
  end
  
  def with_content_tag?
    if(params[:controller] == 'main' and params[:action] == 'index')
      return {:content_tag => 'all'}
    elsif(!@content_tag.nil?)
      return {:content_tag => @content_tag.url_display_name}
    else
      return {:content_tag => 'all'}
    end
  end
  
  def canonicalized_category?(category)
    if(category != category.downcase)
      return false
    elsif(category != category.gsub(' ','_'))
      return false
    else
      return true
    end
  end
  
end
