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
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include LoginSystem
  include ExceptionNotifiable
  include InstitutionalLogo
  include ControllerExtensions

  # Scrub sensitive parameters from your log
  filter_parameter_logging :password

  require 'zip_code_to_state'
  require 'image_size'
  
  # please do not show allowable actions
  # TODO: something better than this because I believe this is masking too many errors
  # commented out for development
  # rescue_from ActionController::RoutingError, :with => :do_404
  # rescue_from ActionController::MethodNotAllowed, :with => :do_404
  # rescue_from ActionController::UnknownAction, :with => :do_404

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
  
  def get_counties
    return render(:nothing => true) if !params[:location_id] or params[:location_id].strip == '' or !(location = Location.find(params[:location_id]))
    counties = location.counties.find(:all, :order => 'name', :conditions => "countycode <> '0'")
    @county_options = [['', '']].concat(counties.map{|c| [c.name, c.id]})
    render(:partial => 'shared/county_list', :locals => {:location=> Location.find(params[:location_id])}, :layout => false)
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
      ActiveRecord::Base::logger.info "content tag name is #{content_tag_name}..."
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
  
  
  
end

# custom error classes
class ContentRetrievalError < StandardError
end
