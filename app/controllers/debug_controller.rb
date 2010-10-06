# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
class DebugController < ApplicationController
  layout 'generic'
  before_filter :login_optional
  
  def location
    filteredparams = ParamsFilter.new([:ipaddress],params)
    @search_ip = filteredparams.ipaddress.nil? ? AppConfig.configtable['default_request_ip'] : filteredparams.ipaddress
    @geoip_data = Location.get_geoip_data(@search_ip)
    @location = Location.find_by_geoip(@search_ip)
    if(@location)
      @public_institutions_for_location = @personal[:location].communities.institutions.public_list
    end
  end
  
end