# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file
class County < ActiveRecord::Base
  include CacheTools

  ALL = "all"

  has_many :users
  belongs_to :location

  def self.find_by_geoip(ipaddress = Settings.request_ip_address,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoname = GeoName.find_by_geoip(ipaddress))
        if(location = Location.find_by_abbreviation(geoname.state_abbreviation))
          location.counties.where(name: geoname.county).first
        else
          nil
        end
      else
        nil
      end
    end
  end

end
