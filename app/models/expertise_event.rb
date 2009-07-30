# === COPYRIGHT:
#  Copyright (c) 2005-2009 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class ExpertiseEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :category, :foreign_key => :expertise_id
  
  EVENT_ADDED = 'added'
  EVENT_DELETED = 'deleted'
  
end