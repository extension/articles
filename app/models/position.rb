# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE
include GroupingExtensions

class Position < ActiveRecord::Base
  POSITION_UNKNOWN = 0
  POSITION_SYSTEM = 1
  POSITION_OTHER = 2
  has_many :users
  
  named_scope :filtered, lambda {|options| userfilter_conditions(options)}
  named_scope :displaylist, {:group => "#{table_name}.id",:order => "entrytype,name"}
  
  class << self
    def geteditlist
      find(:all, :conditions => "entrytype = #{Position::POSITION_SYSTEM} or entrytype = #{Position::POSITION_OTHER}", :order => "entrytype,name")
    end
  end
  
end
