# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class GeoName < ActiveRecord::Base
  
  
  def self.find_by_geoip(ipaddress = Settings.request_ip_address)
    if(geoip_data = Location.get_geoip_data(ipaddress))
      if(geoip_data[:country_code] == 'US')
        self.find(:first, :conditions => "feature_name = '#{geoip_data[:city]}' and map_name = '#{geoip_data[:city]}' and state_abbreviation = '#{geoip_data[:region]}'")
      else
        return nil
      end
    else
      return nil
    end
  end

end