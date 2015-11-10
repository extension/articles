# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#
#  see LICENSE file

class Location < ActiveRecord::Base
  include CacheTools

  UNKNOWN = 0
  STATE = 1
  INSULAR = 2
  OUTSIDEUS = 3
  ALL = "all"


  # Constants from pubsite - rename in pubsite code, Location::LOCATION_STATE is redundant no?

  # LOCATION_UNKNOWN = 0
  # LOCATION_STATE = 1
  # LOCATION_INSULAR = 2
  # LOCATION_OUTSIDEUS = 3

  has_many :users
  has_many :counties
  has_many :communities
  has_many :branding_institutions

  scope :displaylist, {:group => "#{table_name}.id",:order => "entrytype,name"}

  scope :states, {:conditions => {:entrytype => STATE}}

  # TODO: review heureka location reporting methods.  Justcode Issue #555


  def get_associated_county(county_string)
    if county = self.counties.find(:first, :conditions => ["counties.name = ?", county_string.strip])
      return county
    else
      return nil
    end
  end

  def self.find_by_abbreviation_or_name(location_string)
    if location = Location.find_by_abbreviation(location_string.strip) or location = Location.find_by_name(location_string.strip)
      return location
    else
      return nil
    end
  end

  def self.find_by_geoip(ipaddress = Settings.request_ip_address,cache_options = {})
    cache_key = self.get_cache_key(__method__,{ipaddress: ipaddress})
    Rails.cache.fetch(cache_key,cache_options) do
      if(geoip_data = self.get_geoip_data(ipaddress))
        if(geoip_data[:country_code] == 'US')
          self.find_by_abbreviation(geoip_data[:region])
        else
          self.find_by_abbreviation('OUTSIDEUS')
        end
      else
        nil
      end
    end
  end

  def self.get_geoip_data(ipaddress = Settings.request_ip_address)
    if(geoip_data_file = Settings.geoip_data_file)
      if File.exists?(geoip_data_file)
        returnhash = {}
        if(data = GeoIP.new(geoip_data_file).city(ipaddress))
          returnhash[:country_code] = data[2]
          returnhash[:region] = data[6]
          returnhash[:city] = data[7]
          returnhash[:postal_code] = data[8]
          returnhash[:lat] = data[9]
          returnhash[:lon] = data[10]
          returnhash[:tz] = data[13]
          return returnhash
        end
      else
        return nil
      end
    else
      return nil
    end
  end
end
