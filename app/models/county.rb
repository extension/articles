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
  #TODO:  review submitted vs. expert questions  Justcode Issue #553
  has_many :expert_questions
  has_many :submitted_questions    
  named_scope :filtered, lambda {|options| userfilter_conditions(options)}

  
  # TODO: review heureka county reporting methods.  Justcode Issue #554
  
  
end
