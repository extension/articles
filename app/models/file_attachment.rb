# === COPYRIGHT:
#  Copyright (c) 2005-2010 North Carolina State University
#  Developed with funding for the National eXtension Initiative.
# === LICENSE:
#  BSD(-compatible)
#  see LICENSE file or view at http://about.extension.org/wiki/LICENSE

class FileAttachment < ActiveRecord::Base
  
  belongs_to :submitted_question
  has_attached_file :attachment, :styles => { :medium => "300x300>", :thumb => "100x100>" }
  
  
end
