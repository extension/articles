# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class DebugController < ApplicationController
  layout 'generic'
  before_filter :signin_optional

  def items

  end

  def location
    filteredparams = ParamsFilter.new([:ipaddress],params)
    @search_ip = filteredparams.ipaddress.nil? ? Settings.request_ip_address : filteredparams.ipaddress
    @geoip_data = Location.get_geoip_data(@search_ip)
    @geo_location = Location.find_by_geoip(@search_ip)
    @geo_county = County.find_by_geoip(@search_ip)
    @geoname = GeoName.find_by_geoip(@search_ip)

    if(@geo_location)
      @public_institutions_for_location = @geo_location.branding_institutions
    end
  end

  def session_information

  end

  # convenience function to make my life easier right now
  def resource_redirects
    output = []
    PublishingCommunity.all.each do |pc|
      pc.tag_names.each do |tagname|
        gsubtext = '[\\\+_\s]'
        redirect_string = "redirectmatch permanent ^/#{tagname.gsub(' ',gsubtext)}/?$ http://#{Settings.urlwriter_host}/#{tagname.gsub(' ','_')}"
        output << redirect_string
      end
    end

    return render :text => output.join("\n")

  end


end
