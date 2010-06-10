# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class AnnotationEvent < ActiveRecord::Base
  belongs_to :user
  belongs_to :annotation, :foreign_key => :url
  
  EVENT_ADDED = 'added'
  EVENT_DELETED = 'deleted'
end