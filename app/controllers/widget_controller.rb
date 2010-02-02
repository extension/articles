# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

require 'net/http'
require 'uri'

class WidgetController < ApplicationController  
  layout 'widgets'
  #has_rakismet :only => [:create_from_widget]
  
  # ask widget pulled from remote iframe
  def index
    if params[:location]
      @location = Location.find_by_abbreviation(params[:location].strip)
      if params[:county] and @location
        @county = County.find_by_name_and_location_id(params[:county].strip, @location.id)
      end 
    end
    
    @fingerprint = params[:id]
    @host_name = request.host_with_port
    render :layout => false
  end
  
  def create_from_widget
    if request.post?  
      uri = URI.parse(url_for(:controller => 'api/aae', :action => :ask, :format => :json))
      http = Net::HTTP.new(uri.host, uri.port)
      response = http.post(uri.path, "aae_question=#{params[:aae_question]}&aae_email=#{params[:aae_email]}&aae_email_confirmation=#{params[:aae_email_confirmation]}&widget_id=#{params[:id]}&type=widget")
        
      render :layout => false
      return
    end
  end
  
end