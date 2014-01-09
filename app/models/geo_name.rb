# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class GeoName < ActiveRecord::Base
  geocoded_by :address, :latitude  => :lat, :longitude => :long


  def address
    [feature_name, state_abbrevation, 'US'].compact.join(', ')
  end


  def self.find_by_geoip(ipaddress = Settings.request_ip_address)
    if(geoip_data = Location.get_geoip_data(ipaddress))
      if(geoip_data[:country_code] == 'US')
        self.where("state_abbreviation = '#{geoip_data[:region]}'").where("feature_name = '#{geoip_data[:city]}'").near([geoip_data[:lat], geoip_data[:lon]],10).first
      else
        return nil
      end
    else
      return nil
    end
  end

end