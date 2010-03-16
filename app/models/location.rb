# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
include GroupingExtensions

class Location < ActiveRecord::Base
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
  has_many :submitted_questions
  
  named_scope :filtered, lambda {|options| userfilter_conditions(options)}
  named_scope :displaylist, {:group => "#{table_name}.id",:order => "entrytype,name"}
    
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
  
end
