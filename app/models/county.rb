# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
include GroupingExtensions

class County < ActiveRecord::Base
  
  ALL = "all"

  has_many :users
  belongs_to :location
  has_many :submitted_questions    
  named_scope :filtered, lambda {|options| userfilter_conditions(options)}
  
  def self.find_by_geoip(ipaddress = AppConfig.configtable['request_ip_address'])
    if(geoname = GeoName.find_by_geoip(ipaddress))
      self.find_by_name(geoname.county)
    else
      return nil
    end
  end
  
end
