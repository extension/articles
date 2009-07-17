# === COPYRIGHT:
#  Copyright (c) 2005-2006 North Carolina State University
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
  include ArrayStats
  include Logo
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
  before_filter :disable_link_prefetching
  before_filter :get_tag
  before_filter :personalize
  before_filter :set_request_url_options
  before_filter :set_default_request_ip_address
    
  def set_request_url_options
    ActiveRecord::Base::logger.info "Hello - we are inside set request"  
    
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
    [:category, :order].each do |param|
      params[param] = CGI.unescape(params[param]) if params[param]      
    end
    if params[:categories] and params[:categories].class == Array
      params[:categories].collect! { |c| CGI.unescape(c) }
    end
  end
    
  def do_404
    get_tag if not @category
    personalize if not @personal
    @page_title_text = 'Status 404 - Page Not Found'
    render :template => "/shared/404", :status => "404"
  end
  
  def get_tag
    @blacklist = ['article', 'contents', 'dpl', 'events', 'faq', 'feature',
                  'highlight', 'homage', 'youth', 'learning lessons',
                  'learning lessons home', 'main', 'news', 'beano']
                 
    if params[:category] == 'all'
      @category = Tag.new(:name => 'all')
    elsif params[:category]
      params[:category] = params[:category].strip.downcase.gsub(/_/, ' ')
      
      @category = Tag.find_by_name(params[:category])
      unless @category
        @category = Tag.new(:name => 'all')
        flash.now[:notice] = "The category '"+params[:category]+"' does not exist."
      end
      
    elsif session[:category]
    
      if session[:category] == 'all'
        @category = Tag.new(:name => 'all')
      else
        @category = Tag.find_by_name(session[:category]) 
      end
    else
      @category = Tag.new(:name => 'all')
    end
    session[:category] = @category.name if @category
  end
  
  private
  
  def disable_link_prefetching
    if request.env["HTTP_X_MOZ"] == "prefetch" 
      logger.debug "prefetch detected: sending 403 Forbidden" 
      render(:nothing => true, :status => 403)
      return false
    end
  end
  
  def personalize
    @personal = {}
    
    if cookies[:institution_id]
      begin
        inst = Institution.find(cookies[:institution_id])
      rescue
        cookies[:institution_id] = nil
      end
      @personal[:institution] = inst if inst
      if (inst and @personal[:location].nil?)
        @personal[:location] = @personal[:institution].location
      end
    elsif(refering_institution = Institution.find_by_referer(request.referer))
      cookies[:institution_id] = {:value => refering_institution.id.to_s, :expires => 1.month.from_now}
      @personal[:institution] = refering_institution
      @personal[:location] = refering_institution.location
    end
        
    @personal[:tag] = @category
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
  
  def get_community
    @community = nil
    if @category && @category.name != 'all' && @category.content_community
      @community = @category.content_community
    end
    @personal[:community] = @community
    @topic = @community.topic if @community and @community.topic
  end
  
end

# custom error classes
class ContentRetrievalError < StandardError
end
